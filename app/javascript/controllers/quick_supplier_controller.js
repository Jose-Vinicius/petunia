import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["formContainer", "input", "select", "error"]

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
    event.preventDefault()
    const name = this.inputTarget.value.trim()

    if (!name) {
      this.showError("Por favor, digite o nome do fornecedor/cliente.")
      return
    }

    this.clearError()

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    try {
      const response = await fetch("/suppliers.json", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({ supplier: { name: name } })
      })

      const data = await response.json()

      if (response.ok) {
        const option = new Option(data.name, data.id, true, true)
        this.selectTarget.add(option)
        this.selectTarget.value = data.id

        this.formContainerTarget.style.display = "none"
        this.inputTarget.value = ""
      } else {
        const errorMsg = data.errors ? data.errors.join(", ") : "Erro ao cadastrar fornecedor."
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
