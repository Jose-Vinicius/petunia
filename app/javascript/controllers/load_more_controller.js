import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "wrapper"]

  async loadMore(event) {
    event.preventDefault()
    const btn = event.currentTarget
    const url = btn.href || btn.dataset.url
    if (!url) return

    const originalText = btn.innerHTML
    btn.innerHTML = `<span class="material-symbols-outlined" style="font-size: 1rem; vertical-align: middle;">sync</span> Carregando...`
    btn.style.pointerEvents = "none"

    try {
      const response = await fetch(url, {
        headers: {
          "X-Requested-With": "XMLHttpRequest",
          "Accept": "text/html"
        }
      })

      if (response.ok) {
        const html = await response.text()
        const tempDiv = document.createElement("div")
        tempDiv.innerHTML = html

        const newItems = tempDiv.querySelectorAll("[data-load-more-item]")
        newItems.forEach(item => {
          this.containerTarget.appendChild(item)
        })

        const newWrapper = tempDiv.querySelector("[data-load-more-wrapper]")
        if (newWrapper && this.hasWrapperTarget) {
          this.wrapperTarget.replaceWith(newWrapper)
        } else if (this.hasWrapperTarget) {
          this.wrapperTarget.remove()
        }
      } else {
        btn.innerHTML = originalText
        btn.style.pointerEvents = ""
      }
    } catch (err) {
      console.error("Erro ao carregar mais itens:", err)
      btn.innerHTML = originalText
      btn.style.pointerEvents = ""
    }
  }
}
