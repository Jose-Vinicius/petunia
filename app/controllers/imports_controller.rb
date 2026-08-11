require "csv"

class ImportsController < ApplicationController
  before_action :authenticate_user!

  def new
    @categories = current_account.categories.order(:name)
    @suppliers = current_account.suppliers.order(:name)
    @cost_centers = current_account.cost_centers.order(:name)
    @bank_accounts = current_account.bank_accounts.order(:name)
    @credit_cards = current_account.credit_cards.order(:name)
  end

  def preview
    file = params[:file]

    if file.blank?
      render json: { errors: [ t("imports.create.no_file") ], rows: [] }, status: :unprocessable_content
      return
    end

    importer = TransactionImporterService.new(
      file_path: file.path,
      filename: file.original_filename,
      account: current_account,
      bank_account_id: params[:bank_account_id],
      credit_card_id: params[:credit_card_id]
    )

    preview_data = importer.parse_preview

    if preview_data[:errors].any?
      render json: preview_data, status: :unprocessable_content
      return
    end

    render json: {
      rows: preview_data[:rows],
      collections: {
        categories: current_account.categories.order(:name).map { |c| { id: c.id, name: c.name } },
        suppliers: current_account.suppliers.order(:name).map { |s| { id: s.id, name: s.name } },
        cost_centers: current_account.cost_centers.order(:name).map { |c| { id: c.id, name: c.name } },
        bank_accounts: current_account.bank_accounts.order(:name).map { |b| { id: b.id, name: b.name } },
        credit_cards: current_account.credit_cards.order(:name).map { |c| { id: c.id, name: c.name } }
      }
    }
  end

  def create
    if params[:file].present?
      importer = TransactionImporterService.new(
        file_path: params[:file].path,
        filename: params[:file].original_filename,
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
      return
    end

    raw_txs = params[:transactions]
    if raw_txs.blank?
      render json: { errors: [ "Nenhuma transação enviada para confirmação." ] }, status: :unprocessable_content
      return
    end

    success_count = 0
    errors = []

    ActiveRecord::Base.transaction do
      raw_txs.each_with_index do |tx_data, idx|
        category = find_or_create_entity(Category, tx_data[:category])
        supplier = find_or_create_entity(Supplier, tx_data[:supplier])
        cost_center = find_or_create_entity(CostCenter, tx_data[:cost_center]) if tx_data[:cost_center].present?

        bank_account = find_bank_account(tx_data[:bank_account])
        credit_card = find_credit_card(tx_data[:credit_card])

        tx_type = tx_data[:transaction_type].presence || "expense"
        bank_account ||= current_account.bank_accounts.first if tx_type == "income" || credit_card.blank?

        tx = current_account.transactions.build(
          description: tx_data[:description].to_s.strip,
          amount: tx_data[:amount].to_f.abs,
          date: tx_data[:date].presence || Date.current,
          transaction_type: tx_type,
          category: category,
          supplier: supplier,
          cost_center: cost_center,
          bank_account: tx_type == "income" ? bank_account : (credit_card.present? ? nil : bank_account),
          credit_card: tx_type == "income" ? nil : credit_card
        )

        if tx.save
          success_count += 1
        else
          errors << "Linha #{idx + 1}: #{tx.errors.full_messages.join(', ')}"
        end
      end

      raise ActiveRecord::Rollback if errors.any?
    end

    if errors.empty?
      render json: { success: true, count: success_count, redirect_url: transactions_path, notice: t("imports.create.success", count: success_count) }
    else
      render json: { success: false, errors: errors }, status: :unprocessable_content
    end
  end

  def download_template
    sample = params[:sample] == "true"
    headers = [ "Data", "Descrição", "Valor", "Tipo", "Categoria", "Fornecedor", "Centro de Custo", "Conta Bancária", "Cartão de Crédito" ]

    csv_data = CSV.generate(headers: true, col_sep: ";") do |csv|
      csv << headers
      if sample
        csv << [ "10/08/2026", "Salário Mensal", "3500,00", "Receita", "Salário", "Empresa ACME", "Trabalho", "Nubank", "" ]
        csv << [ "11/08/2026", "Supermercado", "250,50", "Despesa", "Alimentação", "Mercado Central", "Pessoal", "", "Visa Itaú" ]
        csv << [ "12/08/2026", "Restaurante", "45,00", "Despesa", "Alimentação", "Restaurante Gourmet", "Pessoal", "Bradesco", "" ]
      end
    end

    filename = sample ? "modelo_transacoes_exemplo.csv" : "modelo_transacoes_cabecalho.csv"
    send_data "\xEF\xBB\xBF" + csv_data, filename: filename, type: "text/csv; charset=utf-8", disposition: "attachment"
  end

  private

  def find_or_create_entity(klass, entity_data)
    return nil if entity_data.blank?

    if entity_data[:id].present?
      entity = current_account.public_send(klass.table_name).find_by(id: entity_data[:id])
      return entity if entity.present?
    end

    name = entity_data[:name].to_s.strip
    return nil if name.blank?

    current_account.public_send(klass.table_name).find_by("LOWER(name) = ?", name.downcase) ||
      current_account.public_send(klass.table_name).create!(name: name)
  end

  def find_bank_account(bank_data)
    return nil if bank_data.blank?

    if bank_data[:id].present?
      acc = current_account.bank_accounts.find_by(id: bank_data[:id])
      return acc if acc.present?
    end

    name = bank_data[:name].to_s.strip
    return nil if name.blank?

    current_account.bank_accounts.find_by("LOWER(name) = ?", name.downcase)
  end

  def find_credit_card(card_data)
    return nil if card_data.blank?

    if card_data[:id].present?
      card = current_account.credit_cards.find_by(id: card_data[:id])
      return card if card.present?
    end

    name = card_data[:name].to_s.strip
    return nil if name.blank?

    current_account.credit_cards.find_by("LOWER(name) = ?", name.downcase)
  end
end
