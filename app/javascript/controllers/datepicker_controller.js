import { Controller } from "@hotwired/stimulus"

const Portuguese = {
  firstDayOfWeek: 1,
  weekdays: {
    shorthand: ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"],
    longhand: [
      "Domingo",
      "Segunda-feira",
      "Terça-feira",
      "Quarta-feira",
      "Quinta-feira",
      "Sexta-feira",
      "Sábado"
    ]
  },
  months: {
    shorthand: [
      "Jan",
      "Fev",
      "Mar",
      "Abr",
      "Mai",
      "Jun",
      "Jul",
      "Ago",
      "Set",
      "Out",
      "Nov",
      "Dez"
    ],
    longhand: [
      "Janeiro",
      "Fevereiro",
      "Março",
      "Abril",
      "Maio",
      "Junho",
      "Julho",
      "Agosto",
      "Setembro",
      "Outubro",
      "Novembro",
      "Dezembro"
    ]
  },
  rangeSeparator: " até ",
  time_24hr: true
}

export default class extends Controller {
  static values = {
    submitOnChange: { type: Boolean, default: false }
  }

  connect() {
    this.onInput = this.formatMask.bind(this)
    this.element.addEventListener("input", this.onInput)

    const flatpickrFn = window.flatpickr
    if (flatpickrFn) {
      this.fp = flatpickrFn(this.element, {
        locale: Portuguese,
        dateFormat: "d/m/Y",
        allowInput: true,
        onChange: (selectedDates, dateStr) => {
          this.element.dispatchEvent(new Event("change", { bubbles: true }))
          if (this.submitOnChangeValue) {
            const form = this.element.closest("form")
            if (form) {
              form.requestSubmit()
            }
          }
        }
      })
    }
  }

  disconnect() {
    if (this.onInput) {
      this.element.removeEventListener("input", this.onInput)
    }
    if (this.fp) {
      this.fp.destroy()
    }
  }

  formatMask(e) {
    if (e.inputType && e.inputType.startsWith("delete")) return

    let val = this.element.value
    let digits = val.replace(/\D/g, "")

    if (digits.length > 8) {
      digits = digits.slice(0, 8)
    }

    let formatted = ""
    if (digits.length > 0) {
      formatted = digits.slice(0, 2)
      if (digits.length >= 3) {
        formatted += "/" + digits.slice(2, 4)
      }
      if (digits.length >= 5) {
        formatted += "/" + digits.slice(4, 8)
      }
    }

    this.element.value = formatted

    if (formatted.length === 10) {
      this.element.dispatchEvent(new Event("change", { bubbles: true }))
      if (this.submitOnChangeValue) {
        const form = this.element.closest("form")
        if (form) {
          form.requestSubmit()
        }
      }
    }
  }

  setDate(val) {
    if (this.fp && val) {
      if (typeof val === "string" && val.includes("-")) {
        const parts = val.split("-")
        if (parts.length === 3) {
          const d = new Date(parts[0], parts[1] - 1, parts[2])
          this.fp.setDate(d, true, "d/m/Y")
          return
        }
      }
      this.fp.setDate(val, true, "d/m/Y")
    }
  }
}
