import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["drawer", "backdrop"]

  connect() {
    this.close = this.close.bind(this)
    this.windowKeydown = this.windowKeydown.bind(this)
    window.addEventListener("keydown", this.windowKeydown)
  }

  disconnect() {
    window.removeEventListener("keydown", this.windowKeydown)
  }

  toggle(event) {
    if (event) event.preventDefault()
    if (this.drawerTarget.classList.contains("open")) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.drawerTarget.classList.add("open")
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.add("show")
    }
    document.body.style.overflow = "hidden"
  }

  close() {
    if (this.hasDrawerTarget) {
      this.drawerTarget.classList.remove("open")
    }
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("show")
    }
    document.body.style.overflow = ""
  }

  windowKeydown(event) {
    if (event.key === "Escape" && this.drawerTarget.classList.contains("open")) {
      this.close()
    }
  }
}
