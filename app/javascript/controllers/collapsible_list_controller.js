import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "button", "buttonText", "buttonIcon"]
  static values = {
    limit: { type: Number, default: 5 },
    expanded: { type: Boolean, default: false }
  }

  connect() {
    this.updateVisibility()
  }

  toggle(event) {
    if (event) event.preventDefault()
    this.expandedValue = !this.expandedValue
    this.updateVisibility()
  }

  updateVisibility() {
    const total = this.itemTargets.length
    if (total <= this.limitValue) {
      if (this.hasButtonTarget) this.buttonTarget.style.display = "none"
      return
    }

    if (this.hasButtonTarget) this.buttonTarget.style.display = "inline-flex"

    this.itemTargets.forEach((item, index) => {
      if (this.expandedValue || index < this.limitValue) {
        item.style.display = ""
      } else {
        item.style.display = "none"
      }
    })

    if (this.hasButtonTextTarget) {
      const remaining = total - this.limitValue
      this.buttonTextTarget.textContent = this.expandedValue
        ? "Mostrar menos"
        : `Mostrar todos (+${remaining})`
    }

    if (this.hasButtonIconTarget) {
      this.buttonIconTarget.textContent = this.expandedValue ? "expand_less" : "expand_more"
    }
  }
}
