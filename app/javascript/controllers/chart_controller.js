import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js"

export default class extends Controller {
  static values = {
    type: String,
    data: Object
  }

  connect() {
    this.renderChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }

  getChartClass() {
    if (typeof window.Chart !== "undefined") {
      return window.Chart
    }
    if (typeof Chart !== "undefined") {
      return Chart
    }
    return null
  }

  renderChart() {
    const ChartClass = this.getChartClass()
    if (!ChartClass) {
      console.warn("[ChartController] Chart.js not loaded.")
      return
    }

    const canvas = this.element.querySelector("canvas")
    if (!canvas) return

    if (this.chart) {
      this.chart.destroy()
    }

    if (ChartClass.defaults) {
      ChartClass.defaults.color = "rgba(255, 255, 255, 0.7)"
      ChartClass.defaults.borderColor = "rgba(255, 255, 255, 0.08)"
      ChartClass.defaults.font = ChartClass.defaults.font || {}
      ChartClass.defaults.font.family = "'Inter', 'SF Pro', system-ui, -apple-system, sans-serif"
    }

    const data = this.parsedData
    const config = this.buildConfig(data)
    this.chart = new ChartClass(canvas, config)
  }

  get parsedData() {
    if (!this.hasDataValue) return {}
    if (typeof this.dataValue === "object" && this.dataValue !== null) {
      return this.dataValue
    }
    try {
      return JSON.parse(this.dataValue)
    } catch (e) {
      console.error("[ChartController] Error parsing chart data:", e)
      return {}
    }
  }

  buildConfig(data) {
    const type = this.typeValue

    switch (type) {
      case "doughnut":
        return this.doughnutConfig(data)
      case "monthly_bar":
        return this.monthlyBarConfig(data)
      case "balance_line":
        return this.balanceLineConfig(data)
      case "horizontal_bar":
        return this.horizontalBarConfig(data)
      default:
        return { type: "bar", data: { labels: [], datasets: [] } }
    }
  }

  get palette() {
    return [
      "#a78bfa", "#34d399", "#f472b6", "#60a5fa", "#fbbf24",
      "#fb923c", "#a3e635", "#e879f9", "#22d3ee", "#f87171"
    ]
  }

  doughnutConfig(data) {
    const labels = data.labels || []
    const values = data.values || []

    return {
      type: "doughnut",
      data: {
        labels,
        datasets: [{
          data: values,
          backgroundColor: this.palette.slice(0, labels.length),
          borderColor: "rgba(18, 18, 21, 0.8)",
          borderWidth: 2,
          hoverBorderWidth: 0,
          hoverOffset: 6
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        cutout: "65%",
        plugins: {
          legend: {
            position: "bottom",
            labels: {
              padding: 12,
              usePointStyle: true,
              pointStyleWidth: 8,
              font: { size: 11, weight: "500" },
              color: "rgba(255, 255, 255, 0.65)"
            }
          },
          tooltip: {
            backgroundColor: "rgba(24, 24, 27, 0.95)",
            titleColor: "#fff",
            bodyColor: "rgba(255,255,255,0.8)",
            borderColor: "rgba(255,255,255,0.1)",
            borderWidth: 1,
            cornerRadius: 8,
            padding: 10,
            callbacks: {
              label: (ctx) => {
                const val = ctx.parsed
                const total = ctx.dataset.data.reduce((a, b) => a + b, 0)
                const pct = total > 0 ? ((val / total) * 100).toFixed(1) : 0
                return ` R$ ${val.toLocaleString("pt-BR", { minimumFractionDigits: 2 })} (${pct}%)`
              }
            }
          }
        }
      }
    }
  }

  monthlyBarConfig(data) {
    const labels = data.labels || []
    const income = data.income || []
    const expense = data.expense || []

    return {
      type: "bar",
      data: {
        labels,
        datasets: [
          {
            label: "Receitas",
            data: income,
            backgroundColor: "rgba(52, 211, 153, 0.7)",
            borderColor: "#34d399",
            borderWidth: 1,
            borderRadius: 4,
            borderSkipped: false
          },
          {
            label: "Despesas",
            data: expense,
            backgroundColor: "rgba(239, 68, 68, 0.7)",
            borderColor: "#ef4444",
            borderWidth: 1,
            borderRadius: 4,
            borderSkipped: false
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { intersect: false, mode: "index" },
        scales: {
          x: {
            grid: { display: false },
            ticks: { font: { size: 11 }, color: "rgba(255,255,255,0.5)" }
          },
          y: {
            grid: { color: "rgba(255,255,255,0.05)" },
            ticks: {
              font: { size: 11 },
              color: "rgba(255,255,255,0.5)",
              callback: (v) => `R$ ${(v / 1000).toFixed(v >= 1000 ? 1 : 0)}${v >= 1000 ? 'k' : ''}`
            }
          }
        },
        plugins: {
          legend: {
            labels: { usePointStyle: true, pointStyleWidth: 8, font: { size: 11, weight: "500" }, color: "rgba(255,255,255,0.65)", padding: 16 }
          },
          tooltip: {
            backgroundColor: "rgba(24,24,27,0.95)",
            titleColor: "#fff",
            bodyColor: "rgba(255,255,255,0.8)",
            borderColor: "rgba(255,255,255,0.1)",
            borderWidth: 1,
            cornerRadius: 8,
            padding: 10,
            callbacks: {
              label: (ctx) => ` ${ctx.dataset.label}: R$ ${ctx.parsed.y.toLocaleString("pt-BR", { minimumFractionDigits: 2 })}`
            }
          }
        }
      }
    }
  }

  balanceLineConfig(data) {
    const labels = data.labels || []
    const values = data.values || []

    return {
      type: "line",
      data: {
        labels,
        datasets: [{
          label: "Saldo Acumulado",
          data: values,
          borderColor: "#a78bfa",
          borderWidth: 2,
          pointBackgroundColor: "#a78bfa",
          pointBorderColor: "#a78bfa",
          pointRadius: 2,
          pointHoverRadius: 5,
          tension: 0.3,
          fill: {
            target: "origin",
            above: "rgba(167, 139, 250, 0.08)",
            below: "rgba(239, 68, 68, 0.08)"
          }
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { intersect: false, mode: "index" },
        scales: {
          x: {
            grid: { display: false },
            ticks: { font: { size: 10 }, color: "rgba(255,255,255,0.5)", maxTicksLimit: 12 }
          },
          y: {
            grid: { color: "rgba(255,255,255,0.05)" },
            ticks: {
              font: { size: 11 },
              color: "rgba(255,255,255,0.5)",
              callback: (v) => `R$ ${(v / 1000).toFixed(v >= 1000 ? 1 : 0)}${v >= 1000 ? 'k' : ''}`
            }
          }
        },
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: "rgba(24,24,27,0.95)",
            titleColor: "#fff",
            bodyColor: "rgba(255,255,255,0.8)",
            borderColor: "rgba(255,255,255,0.1)",
            borderWidth: 1,
            cornerRadius: 8,
            padding: 10,
            callbacks: {
              label: (ctx) => ` Saldo: R$ ${ctx.parsed.y.toLocaleString("pt-BR", { minimumFractionDigits: 2 })}`
            }
          }
        }
      }
    }
  }

  horizontalBarConfig(data) {
    const labels = data.labels || []
    const values = data.values || []

    return {
      type: "bar",
      data: {
        labels,
        datasets: [{
          data: values,
          backgroundColor: this.palette.slice(0, labels.length).map(c => c + "cc"),
          borderColor: this.palette.slice(0, labels.length),
          borderWidth: 1,
          borderRadius: 4,
          borderSkipped: false
        }]
      },
      options: {
        indexAxis: "y",
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: {
            grid: { color: "rgba(255,255,255,0.05)" },
            ticks: {
              font: { size: 11 },
              color: "rgba(255,255,255,0.5)",
              callback: (v) => `R$ ${(v / 1000).toFixed(v >= 1000 ? 1 : 0)}${v >= 1000 ? 'k' : ''}`
            }
          },
          y: {
            grid: { display: false },
            ticks: { font: { size: 11, weight: "500" }, color: "rgba(255,255,255,0.7)" }
          }
        },
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: "rgba(24,24,27,0.95)",
            titleColor: "#fff",
            bodyColor: "rgba(255,255,255,0.8)",
            borderColor: "rgba(255,255,255,0.1)",
            borderWidth: 1,
            cornerRadius: 8,
            padding: 10,
            callbacks: {
              label: (ctx) => ` R$ ${ctx.parsed.x.toLocaleString("pt-BR", { minimumFractionDigits: 2 })}`
            }
          }
        }
      }
    }
  }
}
