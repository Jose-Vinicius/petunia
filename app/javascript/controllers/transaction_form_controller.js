import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeSelect", "creditCardGroup", "creditCardSelect"]

  connect() {
    this.togglePaymentSources()
  }

  togglePaymentSources() {
    const selectedType = this.typeSelectTarget.value

    if (selectedType === "income") {
      this.creditCardGroupTarget.style.display = "none"
      this.creditCardSelectTarget.value = ""
      this.creditCardSelectTarget.disabled = true
    } else {
      this.creditCardGroupTarget.style.display = "block"
      this.creditCardSelectTarget.disabled = false
    }
  }
}
