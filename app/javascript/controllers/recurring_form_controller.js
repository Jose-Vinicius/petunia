import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "checkbox",
    "fields",
    "monthsInput",
    "amountInput",
    "previewText"
  ]

  connect() {
    this.toggle()
  }

  toggle() {
    if (!this.hasCheckboxTarget) return
    const isChecked = this.checkboxTarget.checked

    if (this.hasFieldsTarget) {
      this.fieldsTarget.style.display = isChecked ? "block" : "none"
    }

    if (isChecked) {
      // Uncheck installment checkbox if present in form
      const installmentCheckbox = document.querySelector('input[name="is_installment"]')
      if (installmentCheckbox && installmentCheckbox.checked) {
        installmentCheckbox.checked = false
        installmentCheckbox.dispatchEvent(new Event("change", { bubbles: true }))
      }
      this.calculate()
    }
  }

  calculate() {
    if (!this.hasPreviewTextTarget) return

    const amountStr = this.hasAmountInputTarget ? this.amountInputTarget.value : "0"
    const monthsStr = this.hasMonthsInputTarget ? this.monthsInputTarget.value : "12"

    const amount = this.parseCurrency(amountStr)
    const months = parseInt(monthsStr, 10) || 12

    if (amount > 0 && months >= 1) {
      const formattedAmount = amount.toLocaleString("pt-BR", {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      })

      if (months === 1) {
        this.previewTextTarget.textContent = `Será gerado 1 lançamento recorrente de R$ ${formattedAmount}.`
      } else {
        this.previewTextTarget.textContent = `Serão gerados ${months} lançamentos recorrentes mensais de R$ ${formattedAmount} cada.`
      }
      this.previewTextTarget.style.display = "block"
    } else {
      this.previewTextTarget.textContent = ""
      this.previewTextTarget.style.display = "none"
    }
  }

  parseCurrency(val) {
    if (typeof val !== "string") return parseFloat(val) || 0
    let str = val.trim().replace(/R\$\s?/, "")
    if (str.includes(",") && str.includes(".")) {
      str = str.replace(/\./g, "").replace(",", ".")
    } else if (str.includes(",")) {
      str = str.replace(",", ".")
    }
    return parseFloat(str) || 0
  }
}
