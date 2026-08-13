import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "typeSelect",
    "creditCardGroup",
    "creditCardSelect",
    "dateInput",
    "competenceDateInput",
    "refundGroup",
    "refundCheckbox",
    "destinationBankAccountGroup",
    "statusSelect"
  ]

  static values = {
    isNew: Boolean
  }

  connect() {
    this.togglePaymentSources()
  }

  togglePaymentSources() {
    const selectedType = this.typeSelectTarget.value

    if (selectedType === "income") {
      this.creditCardGroupTarget.style.display = "none"
      this.creditCardSelectTarget.value = ""
      this.creditCardSelectTarget.disabled = true
      this.toggleRefundGroup(false)
      this.toggleDestinationBankAccount(false)
    } else if (selectedType === "transfer") {
      this.creditCardGroupTarget.style.display = "block"
      this.creditCardSelectTarget.disabled = false
      this.toggleRefundGroup(false)
      this.toggleDestinationBankAccount(true)
    } else {
      // expense
      this.creditCardGroupTarget.style.display = "block"
      this.creditCardSelectTarget.disabled = false
      this.toggleRefundGroup(Boolean(this.creditCardSelectTarget.value))
      this.toggleDestinationBankAccount(false)
    }

    this.updateCompetenceDate()
  }

  toggleRefundGroup(show) {
    if (this.hasRefundGroupTarget) {
      this.refundGroupTarget.style.display = show ? "block" : "none"
      if (!show && this.hasRefundCheckboxTarget) {
        this.refundCheckboxTarget.checked = false
      }
    }
  }

  toggleDestinationBankAccount(show) {
    if (this.hasDestinationBankAccountGroupTarget) {
      this.destinationBankAccountGroupTarget.style.display = show ? "block" : "none"
      if (!show) {
        const select = this.destinationBankAccountGroupTarget.querySelector("select")
        if (select) select.value = ""
      }
    }
  }

  updateCompetenceDate() {
    // Only auto-calculate competence date for NEW transactions
    if (!this.isNewValue) return

    const purchaseDateStr = this.hasDateInputTarget ? this.dateInputTarget.value : null
    if (!purchaseDateStr) return

    const selectedOption = this.hasCreditCardSelectTarget && this.creditCardSelectTarget.selectedOptions
      ? this.creditCardSelectTarget.selectedOptions[0]
      : null

    const closingDay = selectedOption && selectedOption.dataset.closingDay
      ? parseInt(selectedOption.dataset.closingDay, 10)
      : null

    const dueDay = selectedOption && selectedOption.dataset.dueDay
      ? parseInt(selectedOption.dataset.dueDay, 10)
      : null

    if (closingDay && dueDay && this.hasCompetenceDateInputTarget) {
      const calculatedDate = this.calculateCompetenceDate(purchaseDateStr, closingDay, dueDay)
      if (calculatedDate) {
        this.setInputValue(this.competenceDateInputTarget, calculatedDate)
      }
    } else if (this.hasCompetenceDateInputTarget) {
      this.setInputValue(this.competenceDateInputTarget, purchaseDateStr)
    }

    if (this.hasStatusSelectTarget) {
      const todayStr = new Date().toISOString().split("T")[0]
      if (purchaseDateStr > todayStr) {
        this.statusSelectTarget.value = "pending"
      } else {
        this.statusSelectTarget.value = "realized"
      }
    }
  }

  setInputValue(target, val) {
    if (!target) return
    target.value = val
    if (target._flatpickr) {
      target._flatpickr.setDate(val, true, "Y-m-d")
    }
  }

  calculateCompetenceDate(purchaseDateStr, closingDay, dueDay) {
    const parts = purchaseDateStr.split("-")
    if (parts.length !== 3) return null

    let year = parseInt(parts[0], 10)
    let month = parseInt(parts[1], 10)
    const day = parseInt(parts[2], 10)

    if (isNaN(year) || isNaN(month) || isNaN(day)) return null

    if (day > closingDay) {
      month += 1
      if (month > 12) {
        month = 1
        year += 1
      }
    }

    if (dueDay <= closingDay) {
      month += 1
      if (month > 12) {
        month = 1
        year += 1
      }
    }

    const daysInMonth = new Date(year, month, 0).getDate()
    const actualDueDay = Math.min(dueDay, daysInMonth)

    const yyyy = year.toString()
    const mm = month.toString().padStart(2, "0")
    const dd = actualDueDay.toString().padStart(2, "0")

    return `${yyyy}-${mm}-${dd}`
  }
}
