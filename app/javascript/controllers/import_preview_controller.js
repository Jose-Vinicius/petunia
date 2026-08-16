import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "fileInput", "formContainer", "previewContainer", "loadingContainer",
    "rowsContainer", "tableBody", "rowCount", "totalAmount", "errorContainer", "confirmBtn"
  ]

  static values = {
    rows: Array,
    collections: Object
  }

  connect() {
    this.rows = this.hasRowsValue ? this.rowsValue : []
    this.collections = this.hasCollectionsValue ? this.collectionsValue : {}
    if (this.containerTarget && this.rows.length > 0) {
      this.renderPreviewTable()
    }
  }

  get containerTarget() {
    if (this.hasRowsContainerTarget) return this.rowsContainerTarget
    if (this.hasTableBodyTarget) return this.tableBodyTarget
    return null
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
        if (this.hasFormContainerTarget) this.formContainerTarget.style.display = "none"
        if (this.hasPreviewContainerTarget) this.previewContainerTarget.style.display = "block"
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
    const container = this.containerTarget
    if (!container) return
    container.innerHTML = ""

    if (this.rows.length === 0) {
      container.innerHTML = `<div style="text-align: center; padding: 2rem 1rem; color: var(--text-secondary);">Nenhuma transação encontrada na planilha.</div>`
      this.updateRowCount()
      return
    }

    this.rows.forEach((row, index) => {
      const card = document.createElement("div")
      card.className = "preview-row-item"
      card.dataset.rowIndex = index
      if (row.installment_group_id) {
        card.dataset.groupId = row.installment_group_id
      }
      card.style.display = "flex"
      card.style.alignItems = "center"
      card.style.gap = "0.5rem"
      card.style.padding = "0.45rem 0.75rem"
      card.style.borderBottom = "1px solid var(--border, #27272a)"
      card.style.minWidth = "1550px"

      const formattedAmount = row.amount !== null && row.amount !== undefined ? String(row.amount).replace('.', ',') : '0,00'
      const formattedDate = this.formatDateToBr(row.date)
      const formattedCompetenceDate = this.formatDateToBr(row.competence_date)

      card.innerHTML = `
        <div style="min-width: 120px; flex: 1;">
          <input type="text" placeholder="dd/mm/aaaa" value="${formattedDate}" class="form-input preview-date-input" style="padding: 0.4rem 0.5rem; font-size: 0.85rem; width: 100%; box-sizing: border-box;" data-field="date" />
        </div>
        <div style="min-width: 120px; flex: 1;">
          <input type="text" placeholder="dd/mm/aaaa" value="${formattedCompetenceDate}" class="form-input preview-date-input" style="padding: 0.4rem 0.5rem; font-size: 0.85rem; width: 100%; box-sizing: border-box;" data-field="competence_date" />
        </div>
        <div style="min-width: 220px; flex: 2.2;">
          <input type="text" value="${this.escapeHtml(row.description)}" class="form-input" style="padding: 0.4rem 0.5rem; font-size: 0.85rem; width: 100%; box-sizing: border-box;" data-field="description" placeholder="Descrição" />
        </div>
        <div style="min-width: 110px; flex: 1;">
          <input type="text" inputmode="decimal" value="${formattedAmount}" class="form-input" style="padding: 0.4rem 0.5rem; font-size: 0.85rem; width: 100%; box-sizing: border-box;" data-field="amount" placeholder="0,00" />
        </div>
        <div style="min-width: 110px; flex: 1;">
          <select class="form-input" style="padding: 0.4rem 0.5rem; font-size: 0.85rem; width: 100%; box-sizing: border-box;" data-field="transaction_type">
            <option value="expense" ${row.transaction_type === "expense" ? "selected" : ""}>Despesa</option>
            <option value="income" ${row.transaction_type === "income" ? "selected" : ""}>Receita</option>
            <option value="transfer" ${row.transaction_type === "transfer" ? "selected" : ""}>Transferência</option>
          </select>
        </div>
        <div style="min-width: 140px; flex: 1.3;">
          ${this.buildSelectHtml("category", row.category, this.collections.categories)}
        </div>
        <div style="min-width: 140px; flex: 1.3;">
          ${this.buildSelectHtml("supplier", row.supplier, this.collections.suppliers)}
        </div>
        <div style="min-width: 130px; flex: 1.2;">
          ${this.buildSelectHtml("cost_center", row.cost_center, this.collections.cost_centers, true)}
        </div>
        <div style="min-width: 130px; flex: 1.2;">
          ${this.buildSelectHtml("bank_account", row.bank_account, this.collections.bank_accounts, true)}
        </div>
        <div style="min-width: 130px; flex: 1.2;">
          ${this.buildSelectHtml("credit_card", row.credit_card, this.collections.credit_cards, true)}
        </div>
        <div style="min-width: 70px; text-align: center;">
          <input type="number" min="1" max="99" value="${row.current_installment || 1}" class="form-input" style="padding: 0.4rem 0.3rem; font-size: 0.85rem; width: 100%; box-sizing: border-box; text-align: center;" data-field="current_installment" />
        </div>
        <div style="min-width: 70px; text-align: center;">
          <input type="number" min="1" max="99" value="${row.total_installments || row.installments_count || 1}" class="form-input" style="padding: 0.4rem 0.3rem; font-size: 0.85rem; width: 100%; box-sizing: border-box; text-align: center;" data-field="total_installments" />
        </div>
        <div style="min-width: 65px; text-align: center; display: flex; justify-content: center; align-items: center;">
          <input type="checkbox" ${row.is_refund ? "checked" : ""} class="form-checkbox" data-field="is_refund" style="width: 16px; height: 16px; cursor: pointer;" />
        </div>
        <div style="min-width: 45px; text-align: center; display: flex; justify-content: center; align-items: center;">
          <button type="button" class="btn btn-ghost" style="padding: 0.3rem 0.4rem; color: var(--error, #ef4444);" data-action="click->import-preview#removeRow" title="Excluir lançamento">
            <span class="material-symbols-outlined" style="font-size: 1.15rem; vertical-align: middle;">delete</span>
          </button>
        </div>
      `

      container.appendChild(card)
      this.applyFieldHighlights(card)
    })

    this.initDateInputs()
    this.updateRowCount()

    container.querySelectorAll("select, input").forEach(element => {
      element.addEventListener("change", (e) => {
        const cardElement = e.target.closest("[data-row-index]")
        if (cardElement) this.applyFieldHighlights(cardElement)
        if (e.target.dataset.field === "amount") this.updateRowCount()
      })
      if (element.dataset.field === "amount") {
        element.addEventListener("input", () => this.updateRowCount())
      }
    })
  }

  formatDateToBr(dateStr) {
    if (!dateStr) return ""
    if (typeof dateStr === "string" && dateStr.includes("-")) {
      const parts = dateStr.split("T")[0].split("-")
      if (parts.length === 3) {
        return `${parts[2].padStart(2, "0")}/${parts[1].padStart(2, "0")}/${parts[0]}`
      }
    }
    return dateStr
  }

  initDateInputs() {
    const container = this.containerTarget
    if (!container) return
    const inputs = container.querySelectorAll(".preview-date-input")
    inputs.forEach(input => {
      input.addEventListener("input", (e) => {
        if (e.inputType && e.inputType.startsWith("delete")) return
        let val = input.value
        let digits = val.replace(/\D/g, "").slice(0, 8)
        let formatted = ""
        if (digits.length > 0) {
          formatted = digits.slice(0, 2)
          if (digits.length >= 3) formatted += "/" + digits.slice(2, 4)
          if (digits.length >= 5) formatted += "/" + digits.slice(4, 8)
        }
        input.value = formatted
      })

      if (window.flatpickr) {
        window.flatpickr(input, {
          locale: {
            firstDayOfWeek: 1,
            weekdays: { shorthand: ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"], longhand: ["Domingo", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"] },
            months: {
              shorthand: ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"],
              longhand: ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]
            }
          },
          dateFormat: "d/m/Y",
          allowInput: true,
          onChange: () => {
            input.dispatchEvent(new Event("change", { bubbles: true }))
          }
        })
      }
    })
  }

  buildSelectHtml(fieldKey, fieldValue, collection, allowBlank = false) {
    const isNew = fieldValue ? fieldValue.is_new : false
    const name = fieldValue ? fieldValue.name : ""
    const id = fieldValue ? fieldValue.id : null

    let options = allowBlank ? `<option value="">(Nenhum)</option>` : ""

    let matched = false
    if (collection) {
      collection.forEach(item => {
        const selected = id === item.id || (name && name.toLowerCase() === item.name.toLowerCase())
        if (selected) matched = true
        options += `<option value="${item.id}" ${selected ? "selected" : ""}>🟢 ${this.escapeHtml(item.name)}</option>`
      })
    }

    if (isNew && name && !matched) {
      options += `<option value="new:${this.escapeHtml(name)}" selected>🟡 ✨ Novo: "${this.escapeHtml(name)}"</option>`
    }

    return `<select class="form-input entity-select" style="padding: 0.4rem 0.4rem; font-size: 0.85rem; width: 100%; box-sizing: border-box;" data-field="${fieldKey}">${options}</select>`
  }

  applyFieldHighlights(cardDiv) {
    if (!cardDiv) return
    cardDiv.querySelectorAll(".entity-select").forEach(select => {
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
    const card = event.currentTarget.closest("[data-row-index]")
    if (card) {
      card.remove()
      this.updateRowCount()
    }
  }

  updateRowCount() {
    const container = this.containerTarget
    const items = container ? container.querySelectorAll("[data-row-index]") : []
    const count = items.length

    if (this.hasRowCountTarget) {
      this.rowCountTarget.innerHTML = `
        <span class="material-symbols-outlined" style="font-size: 1.1rem; color: var(--primary, #a78bfa);">receipt_long</span>
        ${count} ${count === 1 ? 'transação' : 'transações'}
      `
    }

    let totalSum = 0
    items.forEach(card => {
      const amountVal = card.querySelector('[data-field="amount"]')?.value || '0'
      const parsed = parseFloat(amountVal.replace(/\./g, '').replace(',', '.'))
      if (!isNaN(parsed)) {
        totalSum += parsed
      }
    })

    if (this.hasTotalAmountTarget) {
      const formattedTotal = totalSum.toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
      this.totalAmountTarget.innerHTML = `
        <span class="material-symbols-outlined" style="font-size: 1.1rem;">payments</span>
        Total: R$ ${formattedTotal}
      `
    }
  }

  cancelPreview() {
    if (this.hasPreviewContainerTarget) this.previewContainerTarget.style.display = "none"
    if (this.hasFormContainerTarget) this.formContainerTarget.style.display = "block"
    if (this.hasFileInputTarget) this.fileInputTarget.value = ""
    this.clearErrors()
  }

  async confirmImport(event) {
    event.preventDefault()

    const container = this.containerTarget
    const items = container ? container.querySelectorAll("[data-row-index]") : []

    if (items.length === 0) {
      this.showError("Nenhuma transação na lista para importar.")
      return
    }

    const payloadTransactions = []

    items.forEach(card => {
      const date = card.querySelector('[data-field="date"]')?.value
      const competence_date = card.querySelector('[data-field="competence_date"]')?.value
      const description = card.querySelector('[data-field="description"]')?.value
      const rawAmount = card.querySelector('[data-field="amount"]')?.value || '0'
      const amount = rawAmount.replace(/\./g, '').replace(',', '.')
      const transaction_type = card.querySelector('[data-field="transaction_type"]')?.value
      const current_installment = parseInt(card.querySelector('[data-field="current_installment"]')?.value || '1', 10)
      const total_installments = parseInt(card.querySelector('[data-field="total_installments"]')?.value || '1', 10)
      const is_refund = card.querySelector('[data-field="is_refund"]')?.checked || false

      const catVal = card.querySelector('[data-field="category"]')?.value
      const supVal = card.querySelector('[data-field="supplier"]')?.value
      const ccVal = card.querySelector('[data-field="cost_center"]')?.value
      const bankVal = card.querySelector('[data-field="bank_account"]')?.value
      const cardVal = card.querySelector('[data-field="credit_card"]')?.value

      const installment_group_id = card.dataset.groupId || null

      payloadTransactions.push({
        date: date,
        competence_date: competence_date,
        description: description,
        amount: amount,
        transaction_type: transaction_type,
        current_installment: current_installment,
        total_installments: total_installments,
        installments_count: total_installments,
        installment_group_id: installment_group_id,
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
