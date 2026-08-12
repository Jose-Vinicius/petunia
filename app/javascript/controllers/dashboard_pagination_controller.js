import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "pageInfo", "prevBtn", "nextBtn", "controls"]
  static values = { pageSize: { type: Number, default: 5 } }

  connect() {
    this.currentPage = 1
    this.update()
  }

  prev() {
    if (this.currentPage > 1) {
      this.currentPage--
      this.update()
    }
  }

  next() {
    if (this.currentPage < this.totalPages) {
      this.currentPage++
      this.update()
    }
  }

  update() {
    const totalItems = this.itemTargets.length
    this.totalPages = Math.ceil(totalItems / this.pageSizeValue) || 1

    if (totalItems <= this.pageSizeValue) {
      if (this.hasControlsTarget) this.controlsTarget.style.display = "none"
      this.itemTargets.forEach(el => { el.style.display = "" })
      return
    }

    if (this.hasControlsTarget) this.controlsTarget.style.display = "flex"

    const startIdx = (this.currentPage - 1) * this.pageSizeValue
    const endIdx = startIdx + this.pageSizeValue

    this.itemTargets.forEach((el, idx) => {
      if (idx >= startIdx && idx < endIdx) {
        el.style.display = ""
      } else {
        el.style.display = "none"
      }
    })

    if (this.hasPageInfoTarget) {
      this.pageInfoTarget.textContent = `Página ${this.currentPage} de ${this.totalPages}`
    }

    if (this.hasPrevBtnTarget) {
      this.prevBtnTarget.disabled = this.currentPage === 1
      this.prevBtnTarget.style.opacity = this.currentPage === 1 ? "0.4" : "1"
      this.prevBtnTarget.style.cursor = this.currentPage === 1 ? "not-allowed" : "pointer"
    }

    if (this.hasNextBtnTarget) {
      this.hasNextBtnTarget.disabled = this.currentPage === this.totalPages
      this.hasNextBtnTarget.style.opacity = this.currentPage === this.totalPages ? "0.4" : "1"
      this.hasNextBtnTarget.style.cursor = this.currentPage === this.totalPages ? "not-allowed" : "pointer"
    }
  }
}
