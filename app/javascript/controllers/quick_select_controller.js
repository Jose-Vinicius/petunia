import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["formContainer", "input", "select", "error"]
  static values = {
    url: String,
    paramName: String,
    blankError: { type: String, default: "Por favor, digite o nome." }
  }

  toggle() {
    const isHidden = this.formContainerTarget.style.display === "none" || !this.formContainerTarget.style.display
    this.formContainerTarget.style.display = isHidden ? "block" : "none"
    if (isHidden) {
      this.inputTarget.value = ""
      this.inputTarget.focus()
      this.clearError()
    }
  }

  async submit(event) {
    if (event) event.preventDefault()
    const name = this.inputTarget.value.trim()

    if (!name) {
      this.showError(this.blankErrorValue)
      return
    }

    this.clearError()

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    try {
      const payload = {}
      payload[this.paramNameValue] = { name: name }

      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify(payload)
      })

      const data = await response.json()

      if (response.ok) {
        const option = new Option(data.name, data.id, true, true)
        this.selectTarget.add(option)
        this.selectTarget.value = data.id

        this.formContainerTarget.style.display = "none"
        this.inputTarget.value = ""
      } else {
        const errorMsg = data.errors ? data.errors.join(", ") : "Erro ao realizar o cadastro."
        this.showError(errorMsg)
      }
    } catch (err) {
      this.showError("Erro na requisição. Tente novamente.")
    }
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.style.display = "block"
    }
  }

  clearError() {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = ""
      this.errorTarget.style.display = "none"
    }
  }
}
