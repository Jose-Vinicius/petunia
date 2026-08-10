require "csv"

class ImportsController < ApplicationController
  before_action :authenticate_user!


  def new
    @bank_accounts = current_account.bank_accounts.order(:name)
    @credit_cards = current_account.credit_cards.order(:name)
  end

  def create
    file = params[:file]

    if file.blank?
      redirect_to transactions_path, alert: t("imports.create.no_file")
      return
    end

    importer = TransactionImporterService.new(
      file_path: file.path,
      filename: file.original_filename,
      account: current_account,
      bank_account_id: params[:bank_account_id],
      credit_card_id: params[:credit_card_id]
    )

    result = importer.call

    if result.success_count > 0
      notice_msg = t("imports.create.success", count: result.success_count)
      notice_msg += " (#{result.error_count} erros)" if result.error_count > 0
      redirect_to transactions_path, status: :see_other, notice: notice_msg
    else
      alert_msg = t("imports.create.error_html", errors: result.errors.join("; "))
      redirect_to transactions_path, status: :see_other, alert: alert_msg
    end
  end

  def download_template
    sample = params[:sample] == "true"
    headers = [ "Data", "Descrição", "Valor", "Tipo", "Categoria", "Centro de Custo" ]

    csv_data = CSV.generate(headers: true, col_sep: ";") do |csv|
      csv << headers
      if sample
        csv << [ "10/08/2026", "Salário Mensal", "3500,00", "Receita", "Salário", "Trabalho" ]
        csv << [ "11/08/2026", "Supermercado", "250,50", "Despesa", "Alimentação", "Pessoal" ]
        csv << [ "12/08/2026", "Restaurante", "45,00", "Despesa", "Alimentação", "Pessoal" ]
      end
    end

    filename = sample ? "modelo_transacoes_exemplo.csv" : "modelo_transacoes_cabecalho.csv"
    send_data "\xEF\xBB\xBF" + csv_data, filename: filename, type: "text/csv; charset=utf-8", disposition: "attachment"
  end
end
