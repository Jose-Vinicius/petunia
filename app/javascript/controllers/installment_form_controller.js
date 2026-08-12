import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "checkbox",
    "fields",
    "installmentsInput",
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
      this.calculate()
    }
  }

  calculate() {
    if (!this.hasPreviewTextTarget) return

    const amountStr = this.hasAmountInputTarget ? this.amountInputTarget.value : "0"
    const countStr = this.hasInstallmentsInputTarget ? this.installmentsInputTarget.value : "2"

    const totalAmount = this.parseCurrency(amountStr)
    const count = parseInt(countStr, 10) || 2

    if (totalAmount > 0 && count >= 2) {
      const perInstallment = (totalAmount / count).toLocaleString("pt-BR", {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      })

      this.previewTextTarget.textContent = `Serão geradas ${count} parcelas de R$ ${perInstallment} cada.`
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
