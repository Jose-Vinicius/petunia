class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: [ :edit, :update, :destroy ]

  def index
    load_index_data
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def new
    @transaction = current_account.transactions.build(
      date: Date.current,
      transaction_type: params[:type] || "expense"
    )
    load_form_options
  end

  def create
    if params[:is_installment] == "1" && params[:total_installments].to_i >= 2
      creator = InstallmentTransactionCreator.new(
        account: current_account,
        base_params: transaction_params,
        installments_count: params[:total_installments],
        total_amount: transaction_params[:amount]
      )
      txs = creator.call

      if txs.present?
        respond_to do |format|
          msg = "#{txs.size} parcelas criadas com sucesso!"
          format.html { redirect_to transactions_path, status: :see_other, notice: msg }
          format.turbo_stream do
            load_index_data
            flash.now[:notice] = msg
            render :update_success
          end
        end
      else
        @transaction = current_account.transactions.build(transaction_params)
        @transaction.errors.add(:base, "Não foi possível criar as parcelas. Verifique os dados fornecidos.")
        load_form_options
        render :new, status: :unprocessable_content
      end
    else
      @transaction = current_account.transactions.build(transaction_params)

      if @transaction.save
        respond_to do |format|
          format.html { redirect_to transactions_path, status: :see_other, notice: t("transactions.create.success") }
          format.turbo_stream do
            load_index_data
            flash.now[:notice] = t("transactions.create.success")
            render :update_success
          end
        end
      else
        load_form_options
        render :new, status: :unprocessable_content
      end
    end
  end

  def edit
    load_form_options
  end

  def update
    if @transaction.update(transaction_params)
      respond_to do |format|
        format.html { redirect_to transactions_path, status: :see_other, notice: t("transactions.update.success") }
        format.turbo_stream do
          load_index_data
          flash.now[:notice] = t("transactions.update.success")
          render :update_success
        end
      end
    else
      load_form_options
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if params[:delete_all_installments] == "1" && @transaction.installment?
      count = current_account.transactions.by_group(@transaction.installment_group_id).destroy_all.size
      msg = "#{count} parcelas excluídas com sucesso!"
    else
      @transaction.destroy
      msg = t("transactions.destroy.success")
    end

    redirect_to transactions_path, notice: msg
  end

  private

  def set_transaction
    @transaction = current_account.transactions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to transactions_path, alert: t("transactions.errors.not_found")
  end

  def parse_date_param(param_val)
    return nil if param_val.blank?
    Date.parse(param_val.to_s) rescue nil
  end

  def load_form_options
    @categories = current_account.categories.order(:name)
    @suppliers = current_account.suppliers.order(:name)
    @cost_centers = current_account.cost_centers.order(:name)
    @bank_accounts = current_account.bank_accounts.order(:name)
    @credit_cards = current_account.credit_cards.order(:name)
  end

  def load_index_data
    @categories = current_account.categories.order(:name)
    @suppliers = current_account.suppliers.order(:name)
    @cost_centers = current_account.cost_centers.order(:name)
    @bank_accounts = current_account.bank_accounts.order(:name)
    @credit_cards = current_account.credit_cards.order(:name)

    @selected_types = normalize_array_param(params[:transaction_type])
    @selected_category_ids = normalize_array_param(params[:category_id])
    @selected_supplier_ids = normalize_array_param(params[:supplier_id])
    @selected_cost_center_ids = normalize_array_param(params[:cost_center_id])
    @selected_payment_sources = normalize_array_param(params[:payment_source])
    @date_mode = params[:date_mode].presence || "competence"

    @period = params[:period].presence
    if @period == "all" || params[:clear_dates] == "true"
      @start_date = nil
      @end_date = nil
    elsif @period == "last_month"
      last_m = Date.current.prev_month
      @start_date = last_m.beginning_of_month
      @end_date = last_m.end_of_month
    elsif @period == "last_30_days"
      @start_date = 30.days.ago.to_date
      @end_date = Date.current
    elsif @period == "this_year"
      @start_date = Date.current.beginning_of_year
      @end_date = Date.current.end_of_year
    elsif @period == "this_month"
      @start_date = Date.current.beginning_of_month
      @end_date = Date.current.end_of_month
    elsif params[:start_date].present? || params[:end_date].present?
      @start_date = parse_date_param(params[:start_date])
      @end_date = parse_date_param(params[:end_date])
    elsif params[:month].present?
      if params[:month] == "all"
        @start_date = nil
        @end_date = nil
      elsif params[:month] =~ /\A\d{4}-\d{2}\z/
        year, month_num = params[:month].split("-").map(&:to_i)
        @start_date = Date.new(year, month_num, 1)
        @end_date = @start_date.end_of_month
      end
    else
      @start_date = Date.current.beginning_of_month
      @end_date = Date.current.end_of_month
    end

    scope = current_account.transactions.includes(:category, :supplier, :cost_center, :bank_account, :credit_card, :destination_bank_account)

    date_column = @date_mode == "transaction" ? :date : :competence_date

    if @start_date.present? && @end_date.present?
      scope = scope.where(date_column => @start_date..@end_date)
    elsif @start_date.present?
      scope = scope.where("#{date_column} >= ?", @start_date)
    elsif @end_date.present?
      scope = scope.where("#{date_column} <= ?", @end_date)
    end

    scope = scope.where(transaction_type: @selected_types) if @selected_types.present?
    scope = scope.where(category_id: @selected_category_ids) if @selected_category_ids.present?
    scope = scope.where(supplier_id: @selected_supplier_ids) if @selected_supplier_ids.present?
    scope = scope.where(cost_center_id: @selected_cost_center_ids) if @selected_cost_center_ids.present?

    if @selected_payment_sources.present?
      bank_ids = []
      card_ids = []
      @selected_payment_sources.each do |ps|
        type, id = ps.split("_")
        bank_ids << id if type == "bank"
        card_ids << id if type == "card"
      end

      if bank_ids.present? && card_ids.present?
        scope = scope.where("bank_account_id IN (?) OR credit_card_id IN (?)", bank_ids, card_ids)
      elsif bank_ids.present?
        scope = scope.where(bank_account_id: bank_ids)
      elsif card_ids.present?
        scope = scope.where(credit_card_id: card_ids)
      end
    end

    @transactions = scope.order(date: :desc, created_at: :desc)

    @total_income = scope.income.sum(:amount)
    @total_expense = scope.expense.charges.without_invoice_payments.sum(:amount)
    @balance = @total_income - @total_expense
  end

  private

  def normalize_array_param(param_val)
    return [] if param_val.blank?
    Array(param_val).flatten.reject(&:blank?).map(&:to_s)
  end

  def transaction_params
    params.require(:transaction).permit(
      :transaction_type,
      :description,
      :amount,
      :date,
      :competence_date,
      :category_id,
      :supplier_id,
      :cost_center_id,
      :bank_account_id,
      :credit_card_id,
      :destination_bank_account_id,
      :is_refund
    )
  end
end
