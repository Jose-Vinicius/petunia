import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "fileInput", "formContainer", "previewContainer", "loadingContainer",
    "tableBody", "rowCount", "errorContainer", "confirmBtn"
  ]

  connect() {
    this.rows = []
    this.collections = {}
  }

  async loadPreview(event) {
    event.preventDefault()

    const file = this.fileInputTarget.files[0]
    if (!file) return

    this.showLoading(true)
    this.clearErrors()

    const formData = new FormData()
    formData.append("file", file)

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    try {
      const response = await fetch("/imports/preview", {
        method: "POST",
        headers: {
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: formData
      })

      const data = await response.json()
      this.showLoading(false)

      if (response.ok) {
        this.rows = data.rows || []
        this.collections = data.collections || {}
        this.renderPreviewTable()
        this.formContainerTarget.style.display = "none"
        this.previewContainerTarget.style.display = "block"
      } else {
        const errorMsgs = data.errors ? data.errors.join("; ") : "Erro ao ler planilha."
        this.showError(errorMsgs)
      }
    } catch (err) {
      this.showLoading(false)
      this.showError("Erro na requisição. Verifique o arquivo e tente novamente.")
    }
  }

  renderPreviewTable() {
    this.tableBodyTarget.innerHTML = ""
    this.updateRowCount()

    if (this.rows.length === 0) {
      this.tableBodyTarget.innerHTML = `<tr><td colspan="10" style="text-align: center; padding: 2rem; color: var(--text-secondary);">Nenhuma transação encontrada na planilha.</td></tr>`
      return
    }

    this.rows.forEach((row, index) => {
      const tr = document.createElement("tr")
      tr.dataset.rowIndex = index
      tr.style.borderBottom = "1px solid var(--border, #27272a)"

      const formattedAmount = row.amount !== null && row.amount !== undefined ? String(row.amount).replace('.', ',') : '0,00'

      tr.innerHTML = `
        <td style="padding: 0.4rem 0.3rem;"><input type="date" value="${row.date}" class="form-input" style="padding: 0.3rem; font-size: 0.8rem; width: 100%; box-sizing: border-box;" data-field="date" /></td>
        <td style="padding: 0.4rem 0.3rem;"><input type="date" value="${row.competence_date || ''}" class="form-input" style="padding: 0.3rem; font-size: 0.8rem; width: 100%; box-sizing: border-box;" data-field="competence_date" /></td>
        <td style="padding: 0.4rem 0.3rem;"><input type="text" value="${this.escapeHtml(row.description)}" class="form-input" style="padding: 0.3rem; font-size: 0.8rem; width: 100%; box-sizing: border-box;" data-field="description" /></td>
        <td style="padding: 0.4rem 0.3rem;"><input type="text" inputmode="decimal" value="${formattedAmount}" class="form-input" style="padding: 0.3rem; font-size: 0.8rem; width: 100%; box-sizing: border-box;" data-field="amount" /></td>
        <td style="padding: 0.4rem 0.3rem;">
          <select class="form-input" style="padding: 0.3rem; font-size: 0.8rem; width: 100%; box-sizing: border-box;" data-field="transaction_type">
            <option value="expense" ${row.transaction_type === "expense" ? "selected" : ""}>Despesa</option>
            <option value="income" ${row.transaction_type === "income" ? "selected" : ""}>Receita</option>
            <option value="transfer" ${row.transaction_type === "transfer" ? "selected" : ""}>Transferência</option>
          </select>
        </td>
        <td style="padding: 0.4rem 0.3rem;">${this.buildSelectHtml("category", row.category, this.collections.categories)}</td>
        <td style="padding: 0.4rem 0.3rem;">${this.buildSelectHtml("supplier", row.supplier, this.collections.suppliers)}</td>
        <td style="padding: 0.4rem 0.3rem;">${this.buildSelectHtml("cost_center", row.cost_center, this.collections.cost_centers, true)}</td>
        <td style="padding: 0.4rem 0.3rem;">${this.buildSelectHtml("bank_account", row.bank_account, this.collections.bank_accounts, true)}</td>
        <td style="padding: 0.4rem 0.3rem;">${this.buildSelectHtml("credit_card", row.credit_card, this.collections.credit_cards, true)}</td>
        <td style="padding: 0.4rem 0.3rem;">
          <input type="number" min="1" max="99" value="${row.installments_count || 1}" class="form-input" style="padding: 0.3rem; font-size: 0.8rem; width: 100%; box-sizing: border-box; text-align: center;" data-field="installments_count" />
        </td>
        <td style="padding: 0.4rem 0.3rem; text-align: center;">
          <input type="checkbox" ${row.is_refund ? "checked" : ""} class="form-checkbox" data-field="is_refund" style="width: 16px; height: 16px;" />
        </td>
        <td style="padding: 0.4rem 0.3rem; text-align: center;">
          <button type="button" class="btn btn-ghost" style="padding: 0.2rem 0.4rem; color: var(--error, #ef4444);" data-action="click->import-preview#removeRow">
            <span class="material-symbols-outlined" style="font-size: 1.1rem; vertical-align: middle;">delete</span>
          </button>
        </td>
      `

      this.tableBodyTarget.appendChild(tr)
      this.applyFieldHighlights(tr)
    })

    this.tableBodyTarget.querySelectorAll("select, input").forEach(element => {
      element.addEventListener("change", (e) => {
        const rowTr = e.target.closest("tr")
        if (rowTr) this.applyFieldHighlights(rowTr)
      })
    })
  }

  buildSelectHtml(fieldKey, fieldValue, collection, allowBlank = false) {
    const isNew = fieldValue ? fieldValue.is_new : false
    const name = fieldValue ? fieldValue.name : ""
    const id = fieldValue ? fieldValue.id : null

    let options = allowBlank ? `<option value="">(Nenhum)</option>` : ""

    let matched = false
    collection.forEach(item => {
      const selected = id === item.id || (name && name.toLowerCase() === item.name.toLowerCase())
      if (selected) matched = true
      options += `<option value="${item.id}" ${selected ? "selected" : ""}>🟢 ${this.escapeHtml(item.name)}</option>`
    })

    if (isNew && name && !matched) {
      options += `<option value="new:${this.escapeHtml(name)}" selected>🟡 ✨ Novo: "${this.escapeHtml(name)}"</option>`
    }

    return `<select class="form-input entity-select" style="padding: 0.35rem; font-size: 0.8rem; width: 100%; box-sizing: border-box;" data-field="${fieldKey}">${options}</select>`
  }

  applyFieldHighlights(rowTr) {
    rowTr.querySelectorAll(".entity-select").forEach(select => {
      const val = select.value
      if (!val) {
        select.style.border = "1px solid var(--border, #27272a)"
        select.style.background = "var(--surface-hover, #18181b)"
        select.style.color = "var(--text-primary)"
      } else if (val.startsWith("new:")) {
        // Yellow highlight for NEW entities
        select.style.border = "1.5px solid #facc15"
        select.style.background = "rgba(250, 204, 21, 0.1)"
        select.style.color = "#facc15"
      } else {
        // Green highlight for EXISTING entities
        select.style.border = "1.5px solid #34d399"
        select.style.background = "rgba(52, 211, 153, 0.1)"
        select.style.color = "#34d399"
      }
    })
  }

  removeRow(event) {
    const tr = event.currentTarget.closest("tr")
    if (tr) {
      tr.remove()
      this.updateRowCount()
    }
  }

  updateRowCount() {
    const count = this.tableBodyTarget.querySelectorAll("tr[data-row-index]").length
    if (this.hasRowCountTarget) {
      this.rowCountTarget.textContent = `${count} transações`
    }
  }

  cancelPreview() {
    this.previewContainerTarget.style.display = "none"
    this.formContainerTarget.style.display = "block"
    this.fileInputTarget.value = ""
    this.clearErrors()
  }

  async confirmImport(event) {
    event.preventDefault()

    const trs = this.tableBodyTarget.querySelectorAll("tr[data-row-index]")
    if (trs.length === 0) {
      this.showError("Nenhuma transação na lista para importar.")
      return
    }

    const payloadTransactions = []

    trs.forEach(tr => {
      const date = tr.querySelector('[data-field="date"]')?.value
      const competence_date = tr.querySelector('[data-field="competence_date"]')?.value
      const description = tr.querySelector('[data-field="description"]')?.value
      const rawAmount = tr.querySelector('[data-field="amount"]')?.value || '0'
      const amount = rawAmount.replace(/\./g, '').replace(',', '.')
      const transaction_type = tr.querySelector('[data-field="transaction_type"]')?.value
      const installments_count = parseInt(tr.querySelector('[data-field="installments_count"]')?.value || '1', 10)
      const is_refund = tr.querySelector('[data-field="is_refund"]')?.checked || false

      const catVal = tr.querySelector('[data-field="category"]')?.value
      const supVal = tr.querySelector('[data-field="supplier"]')?.value
      const ccVal = tr.querySelector('[data-field="cost_center"]')?.value
      const bankVal = tr.querySelector('[data-field="bank_account"]')?.value
      const cardVal = tr.querySelector('[data-field="credit_card"]')?.value

      payloadTransactions.push({
        date: date,
        competence_date: competence_date,
        description: description,
        amount: amount,
        transaction_type: transaction_type,
        installments_count: installments_count,
        is_refund: is_refund,
        category: this.parseSelectPayload(catVal),
        supplier: this.parseSelectPayload(supVal),
        cost_center: this.parseSelectPayload(ccVal),
        bank_account: this.parseSelectPayload(bankVal),
        credit_card: this.parseSelectPayload(cardVal)
      })
    })

    this.confirmBtnTarget.disabled = true
    this.confirmBtnTarget.textContent = "Gravando transações..."
    this.clearErrors()

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    try {
      const response = await fetch("/imports", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({ transactions: payloadTransactions })
      })

      const data = await response.json()

      if (response.ok && data.success) {
        window.location.href = data.redirect_url || "/transactions"
      } else {
        this.confirmBtnTarget.disabled = false
        this.confirmBtnTarget.textContent = "Confirmar Importação"
        const errMsgs = data.errors ? data.errors.join("; ") : "Erro ao importar transações."
        this.showError(errMsgs)
      }
    } catch (err) {
      this.confirmBtnTarget.disabled = false
      this.confirmBtnTarget.textContent = "Confirmar Importação"
      this.showError("Erro na requisição. Tente novamente.")
    }
  }

  parseSelectPayload(val) {
    if (!val) return null
    if (val.startsWith("new:")) {
      return { id: null, name: val.replace("new:", "") }
    }
    return { id: parseInt(val, 10), name: null }
  }

  showLoading(show) {
    if (this.hasLoadingContainerTarget) {
      this.loadingContainerTarget.style.display = show ? "block" : "none"
    }
  }

  showError(message) {
    if (this.hasErrorContainerTarget) {
      this.errorContainerTarget.textContent = message
      this.errorContainerTarget.style.display = "block"
    }
  }

  clearErrors() {
    if (this.hasErrorContainerTarget) {
      this.errorContainerTarget.textContent = ""
      this.errorContainerTarget.style.display = "none"
    }
  }

  escapeHtml(str) {
    if (!str) return ""
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;")
  }
}
