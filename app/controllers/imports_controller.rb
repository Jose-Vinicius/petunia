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
      respond_to do |format|
        format.html do
          flash[:alert] = t("imports.create.no_file")
          redirect_to new_import_path, status: :see_other
        end
        format.json { render json: { errors: [ t("imports.create.no_file") ], rows: [] }, status: :unprocessable_content }
      end
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
      respond_to do |format|
        format.html do
          flash[:alert] = preview_data[:errors].join("; ")
          redirect_to new_import_path, status: :see_other
        end
        format.json { render json: preview_data, status: :unprocessable_content }
      end
      return
    end

    @rows = preview_data[:rows]
    @collections = {
      categories: current_account.categories.order(:name).map { |c| { id: c.id, name: c.name } },
      suppliers: current_account.suppliers.order(:name).map { |s| { id: s.id, name: s.name } },
      cost_centers: current_account.cost_centers.order(:name).map { |c| { id: c.id, name: c.name } },
      bank_accounts: current_account.bank_accounts.order(:name).map { |b| { id: b.id, name: b.name } },
      credit_cards: current_account.credit_cards.order(:name).map { |c| { id: c.id, name: c.name } }
    }

    respond_to do |format|
      format.html { render :preview }
      format.json { render json: { rows: @rows, collections: @collections } }
    end
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

        bank_account = find_or_create_bank_account(tx_data[:bank_account])
        credit_card = find_or_create_credit_card(tx_data[:credit_card], bank_account)

        tx_type = tx_data[:transaction_type].presence || "expense"
        if credit_card.present?
          bank_account = nil
        end

        is_refund_val = ActiveModel::Type::Boolean.new.cast(tx_data[:is_refund])
        tx_date = TransactionImporterService.parse_date(tx_data[:date]) || Date.current
        raw_comp_date = TransactionImporterService.parse_date(tx_data[:competence_date])
        parsed_comp_date = raw_comp_date || (credit_card.present? ? credit_card.invoice_competence_for(tx_date) : tx_date)

        tx_attrs = {
          description: tx_data[:description].to_s.strip,
          amount: tx_data[:amount].to_f.abs,
          date: tx_date,
          competence_date: parsed_comp_date,
          transaction_type: tx_type,
          category: category,
          supplier: supplier,
          cost_center: cost_center,
          bank_account: bank_account,
          credit_card: credit_card,
          is_refund: (credit_card.present? && is_refund_val)
        }

        current_inst = [ tx_data[:current_installment].to_i, 1 ].max
        total_inst = [ (tx_data[:total_installments].presence || tx_data[:installments_count].presence || 1).to_i, 1 ].max
        total_inst = [ total_inst, current_inst ].max
        group_id = tx_data[:installment_group_id].presence

        if total_inst > 1 && group_id.blank? && current_inst == 1
          base_params = {
            description: tx_attrs[:description],
            date: tx_attrs[:date],
            competence_date: tx_attrs[:competence_date],
            transaction_type: tx_type,
            category_id: category&.id,
            supplier_id: supplier&.id,
            cost_center_id: cost_center&.id,
            bank_account_id: bank_account&.id,
            credit_card_id: credit_card&.id,
            is_refund: tx_attrs[:is_refund],
            status: "realized"
          }
          creator = InstallmentTransactionCreator.new(
            account: current_account,
            base_params: base_params,
            total_installments: total_inst,
            current_installment: current_inst,
            amount_per_installment: tx_attrs[:amount]
          )
          created_txs = creator.call
          if created_txs.present?
            success_count += created_txs.size
          else
            errors << "Linha #{idx + 1}: Não foi possível criar as parcelas (#{current_inst}/#{total_inst})."
          end
        else
          if total_inst > 1
            tx_attrs[:installment_group_id] = group_id || SecureRandom.uuid
            tx_attrs[:installment_number] = current_inst
            tx_attrs[:total_installments] = total_inst
          end

          tx = current_account.transactions.build(tx_attrs)

          if tx.save
            success_count += 1
          else
            errors << "Linha #{idx + 1}: #{tx.errors.full_messages.join(', ')}"
          end
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
    headers = [ "Data", "Data Competência", "Descrição", "Valor", "Tipo", "Categoria", "Fornecedor", "Centro de Custo", "Conta Bancária", "Cartão de Crédito", "Parcela Atual", "Parcela Total", "Estorno" ]

    p = Axlsx::Package.new
    wb = p.workbook

    wb.add_worksheet(name: "Modelo Transações") do |sheet|
      sheet.add_row headers
      if sample
        types = Array.new(headers.size, :string)
        sheet.add_row [ "10/08/2026", "10/08/2026", "Salário Mensal", "3500,00", "Receita", "Salário", "Empresa ACME", "Trabalho", "Nubank", "", "1", "1", "Não" ], types: types
        sheet.add_row [ "11/08/2026", "10/09/2026", "Supermercado", "250,50", "Despesa", "Alimentação", "Mercado Central", "Pessoal", "", "Visa Itaú", "1", "1", "Não" ], types: types
        sheet.add_row [ "12/08/2026", "10/09/2026", "Smartphone Novo", "100,00", "Despesa", "Eletrônicos", "Loja Tech", "Pessoal", "", "Visa Itaú", "10", "12", "Não" ], types: types
        sheet.add_row [ "13/08/2026", "10/09/2026", "Estorno Compra", "45,00", "Despesa", "Alimentação", "Restaurante Gourmet", "Pessoal", "", "Visa Itaú", "1", "1", "Sim" ], types: types
      end
    end

    filename = sample ? "modelo_transacoes_exemplo.xlsx" : "modelo_transacoes_cabecalho.xlsx"
    send_data p.to_stream.read, filename: filename, type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", disposition: "attachment"
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

  def find_or_create_bank_account(bank_data)
    return nil if bank_data.blank?

    if bank_data[:id].present?
      acc = current_account.bank_accounts.find_by(id: bank_data[:id])
      return acc if acc.present?
    end

    name = bank_data[:name].to_s.strip
    return nil if name.blank?

    current_account.bank_accounts.find_by("LOWER(name) = ?", name.downcase) ||
      current_account.bank_accounts.create!(name: name)
  end

  def find_or_create_credit_card(card_data, bank_account = nil)
    return nil if card_data.blank?

    if card_data[:id].present?
      card = current_account.credit_cards.find_by(id: card_data[:id])
      return card if card.present?
    end

    name = card_data[:name].to_s.strip
    return nil if name.blank?

    existing = current_account.credit_cards.find_by("LOWER(name) = ?", name.downcase)
    return existing if existing.present?

    target_bank = bank_account || current_account.bank_accounts.first || current_account.bank_accounts.create!(name: "Conta Principal")
    current_account.credit_cards.create!(name: name, bank_account: target_bank, limit: 0)
  end
end
