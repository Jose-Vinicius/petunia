import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["chip", "hiddenInputs"]
  static values = {
    name: String,
    selected: { type: Array, default: [] }
  }

  connect() {
    this.updateChips()
  }

  toggle(event) {
    event.preventDefault()
    const chip = event.currentTarget
    const value = chip.dataset.value

    let selected = [...this.selectedValue]
    const idx = selected.indexOf(value)

    if (idx >= 0) {
      selected.splice(idx, 1)
    } else {
      selected.push(value)
    }

    this.selectedValue = selected
    this.updateChips()
    this.updateHiddenInputs()
    this.submitForm()
  }

  updateChips() {
    this.chipTargets.forEach(chip => {
      const value = chip.dataset.value
      const isActive = this.selectedValue.includes(value)

      if (isActive) {
        chip.classList.add("filter-chip--active")
        chip.classList.remove("filter-chip--inactive")
      } else {
        chip.classList.remove("filter-chip--active")
        chip.classList.add("filter-chip--inactive")
      }
    })
  }

  updateHiddenInputs() {
    if (!this.hasHiddenInputsTarget) return

    this.hiddenInputsTarget.innerHTML = ""

    this.selectedValue.forEach(val => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = `${this.nameValue}[]`
      input.value = val
      this.hiddenInputsTarget.appendChild(input)
    })
  }

  submitForm() {
    const form = this.element.closest("form")
    if (form) {
      form.requestSubmit()
    }
  }
}
