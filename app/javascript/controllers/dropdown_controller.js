import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  connect() {
    this.close = this.close.bind(this)
    this.windowClick = this.windowClick.bind(this)
    this.windowKeydown = this.windowKeydown.bind(this)
    window.addEventListener("click", this.windowClick)
    window.addEventListener("keydown", this.windowKeydown)
  }

  disconnect() {
    window.removeEventListener("click", this.windowClick)
    window.removeEventListener("keydown", this.windowKeydown)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    const isOpen = this.menuTarget.classList.contains("show")
    
    // Close any other open dropdowns first
    document.querySelectorAll(".dropdown-menu.show").forEach(menu => {
      if (menu !== this.menuTarget) menu.classList.remove("show")
    })

    if (isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.add("show")
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "true")
    }
  }

  close() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.remove("show")
    }
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "false")
    }
  }

  windowClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  windowKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
