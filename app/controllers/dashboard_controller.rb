class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_filters, only: [ :index, :categories, :transactions ]

  def index
    scope = filtered_transactions_scope

    @monthly_realized_income = scope.income.realized.sum(:amount)
    @monthly_pending_income = scope.income.pending.sum(:amount)
    @monthly_income = @monthly_realized_income + @monthly_pending_income

    @monthly_realized_expense = scope.expense.charges.without_invoice_payments.realized.sum(:amount)
    @monthly_pending_expense = scope.expense.charges.without_invoice_payments.pending.sum(:amount)
    @monthly_expense = @monthly_realized_expense + @monthly_pending_expense

    @monthly_balance = @monthly_income - @monthly_expense

    # Total consolidated liquid balance across all bank accounts (ONLY realized transactions)
    @consolidated_balance = current_account.bank_accounts.sum do |bank_acc|
      income = bank_acc.transactions.income.realized.sum(:amount)
      expense = bank_acc.transactions.expense.realized.sum(:amount)
      transfers_out = bank_acc.transactions.transfer.realized.sum(:amount)
      transfers_in = current_account.transactions.transfer.realized.where(destination_bank_account_id: bank_acc.id).sum(:amount)
      income + transfers_in - expense - transfers_out
    end

    # Projected balance considering pending income and expenses
    @projected_balance = @consolidated_balance + @monthly_pending_income - @monthly_pending_expense

    # Consolidated Credit Card limit metrics
    @total_credit_limit = current_account.credit_cards.sum(:limit)
    @total_credit_used = current_account.credit_cards.sum(&:spent_unpaid)
    @total_credit_available = [ @total_credit_limit - @total_credit_used, 0 ].max
    @credit_usage_percentage = @total_credit_limit > 0 ? ((@total_credit_used / @total_credit_limit.to_f) * 100).round(1) : 0

    # Category breakdown: DB query for page 1 (first 5 categories)
    all_cat_expenses = scope.expense
                           .without_invoice_payments
                           .joins(:category)
                           .group("categories.name")
                           .sum(:amount)
                           .sort_by { |_name, total| -total }

    @total_categories_count = all_cat_expenses.size
    @category_expenses = all_cat_expenses.first(5)
    @categories_has_more = @total_categories_count > 5

    # Recent transactions: DB query for page 1 (first 5 transactions)
    @recent_transactions = scope.includes(:category, :cost_center, :bank_account, :credit_card, :destination_bank_account)
                                .order(date: :desc, created_at: :desc)
                                .limit(5)
                                .offset(0)

    total_tx_count = scope.count
    @transactions_has_more = total_tx_count > 5

    # --- Chart Data Computation ---
    # 1. Donut Chart (Gastos por Categoria)
    cat_totals = all_cat_expenses.first(10)
    @chart_category_data = {
      labels: cat_totals.map(&:first),
      values: cat_totals.map(&:last).map(&:to_f)
    }

    # 2. Monthly Bar Chart (Receita vs Despesa - últimos 6 meses)
    months = (0..5).map { |i| Date.current.beginning_of_month - i.months }.reverse
    date_col = @date_mode == "transaction" ? :date : :competence_date
    @chart_monthly_data = {
      labels: months.map { |m| I18n.l(m, format: "%b/%y") },
      income: months.map { |m| current_account.transactions.where(date_col => m..m.end_of_month).income.sum(:amount).to_f },
      expense: months.map { |m| current_account.transactions.where(date_col => m..m.end_of_month).expense.charges.without_invoice_payments.sum(:amount).to_f }
    }

    # 3. Line Chart (Evolução do Saldo)
    date_col_sym = @date_mode == "transaction" ? :date : :competence_date
    daily_rows = scope.where.not(transaction_type: "transfer")
                      .group(date_col_sym)
                      .order(date_col_sym => :asc)
                      .select("#{date_col_sym} AS day, SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END) AS inc, SUM(CASE WHEN transaction_type = 'expense' AND is_refund = false THEN amount ELSE 0 END) AS exp")
    cum = 0.0
    balance_labels = []
    balance_values = []
    daily_rows.each do |r|
      cum += (r.inc.to_f - r.exp.to_f)
      day_val = r.day
      day_str = day_val.respond_to?(:strftime) ? day_val.strftime("%d/%m") : day_val.to_s
      balance_labels << day_str
      balance_values << cum.round(2)
    end
    @chart_balance_data = { labels: balance_labels, values: balance_values }

    # 4. Horizontal Bar Chart (Top 5 Fornecedores)
    sup_totals = scope.expense
                      .without_invoice_payments
                      .joins(:supplier)
                      .group("suppliers.name")
                      .sum(:amount)
                      .sort_by { |_, v| -v }
                      .first(5)
    @chart_supplier_data = {
      labels: sup_totals.map(&:first),
      values: sup_totals.map(&:last).map(&:to_f)
    }
  end

  def categories
    scope = filtered_transactions_scope
    page = (params[:page].presence || 2).to_i
    limit = 5
    offset = (page - 1) * limit

    all_cat_expenses = scope.expense
                           .without_invoice_payments
                           .joins(:category)
                           .group("categories.name")
                           .sum(:amount)
                           .sort_by { |_name, total| -total }

    @category_expenses = all_cat_expenses.drop(offset).first(limit) || []
    @next_page = page + 1
    @has_more = all_cat_expenses.size > (offset + limit)
    @monthly_expense = scope.expense.charges.without_invoice_payments.sum(:amount)

    render partial: "dashboard/category_expenses_list", layout: false
  end

  def transactions
    scope = filtered_transactions_scope
    page = (params[:page].presence || 2).to_i
    limit = 5
    offset = (page - 1) * limit

    @recent_transactions = scope.includes(:category, :cost_center, :bank_account, :credit_card, :destination_bank_account)
                                .order(date: :desc, created_at: :desc)
                                .limit(limit)
                                .offset(offset)

    total_tx_count = scope.count
    @next_page = page + 1
    @has_more = total_tx_count > (offset + limit)

    render partial: "dashboard/recent_transactions_list", layout: false
  end

  private

  def set_filters
    @categories = current_account.categories.order(:name)
    @suppliers = current_account.suppliers.order(:name)
    @cost_centers = current_account.cost_centers.order(:name)
    @bank_accounts = current_account.bank_accounts.includes(:transactions).order(:name)
    @credit_cards = current_account.credit_cards.includes(:transactions).order(:name)

    @selected_category_ids = normalize_array_param(params[:category_id])
    @selected_supplier_ids = normalize_array_param(params[:supplier_id])
    @selected_cost_center_ids = normalize_array_param(params[:cost_center_id])
    @selected_payment_sources = normalize_array_param(params[:payment_source])
    @selected_types = normalize_array_param(params[:transaction_type])
    @selected_statuses = normalize_array_param(params[:status])
    @date_mode = params[:date_mode].presence || "competence"

    if params[:start_date].present? || params[:end_date].present?
      @start_date = parse_date_param(params[:start_date])
      @end_date = parse_date_param(params[:end_date])
      @period = "custom"
    elsif params[:period].present?
      @period = params[:period]
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
      end
    else
      @period = "this_month"
      @start_date = Date.current.beginning_of_month
      @end_date = Date.current.end_of_month
    end
  end

  def filtered_transactions_scope
    scope = current_account.transactions
    date_column = @date_mode == "transaction" ? :date : :competence_date

    if @start_date.present? && @end_date.present?
      scope = scope.where(date_column => @start_date..@end_date)
    elsif @start_date.present?
      scope = scope.where("#{date_column} >= ?", @start_date)
    elsif @end_date.present?
      scope = scope.where("#{date_column} <= ?", @end_date)
    end

    scope = scope.where(category_id: @selected_category_ids) if @selected_category_ids.present?
    scope = scope.where(supplier_id: @selected_supplier_ids) if @selected_supplier_ids.present?
    scope = scope.where(cost_center_id: @selected_cost_center_ids) if @selected_cost_center_ids.present?
    scope = scope.where(transaction_type: @selected_types) if @selected_types.present?
    scope = scope.where(status: @selected_statuses) if @selected_statuses.present?

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

    scope
  end

  def normalize_array_param(param_val)
    return [] if param_val.blank?
    Array(param_val).flatten.reject(&:blank?).map(&:to_s)
  end

  def parse_date_param(param_val)
    return nil if param_val.blank?
    TransactionImporterService.parse_date(param_val)
  end
end
