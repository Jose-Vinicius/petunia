class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: [ :edit, :update, :destroy ]

  def index
    @categories = current_account.categories.order(:name)
    @cost_centers = current_account.cost_centers.order(:name)
    @bank_accounts = current_account.bank_accounts.order(:name)
    @credit_cards = current_account.credit_cards.order(:name)

    @month = params[:month].presence || Date.current.strftime("%Y-%m")
    @selected_type = params[:transaction_type].presence
    @selected_category_id = params[:category_id].presence
    @selected_cost_center_id = params[:cost_center_id].presence
    @selected_payment_source = params[:payment_source].presence

    scope = current_account.transactions.includes(:category, :cost_center, :bank_account, :credit_card)

    if @month != "all" && @month =~ /\A\d{4}-\d{2}\z/
      year, month_num = @month.split("-").map(&:to_i)
      start_date = Date.new(year, month_num, 1)
      end_date = start_date.end_of_month
      scope = scope.where(date: start_date..end_date)
    end

    scope = scope.where(transaction_type: @selected_type) if @selected_type.present?
    scope = scope.where(category_id: @selected_category_id) if @selected_category_id.present?
    scope = scope.where(cost_center_id: @selected_cost_center_id) if @selected_cost_center_id.present?

    if @selected_payment_source.present?
      type, id = @selected_payment_source.split("_")
      if type == "bank"
        scope = scope.where(bank_account_id: id)
      elsif type == "card"
        scope = scope.where(credit_card_id: id)
      end
    end

    @transactions = scope.order(date: :desc, created_at: :desc)

    @total_income = scope.income.sum(:amount)
    @total_expense = scope.expense.sum(:amount)
    @balance = @total_income - @total_expense

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
    @transaction = current_account.transactions.build(transaction_params)

    if @transaction.save
      redirect_to transactions_path, status: :see_other, notice: t("transactions.create.success")
    else
      load_form_options
      render :new, status: :unprocessable_content
    end
  end

  def edit
    load_form_options
  end

  def update
    if @transaction.update(transaction_params)
      redirect_to transactions_path, status: :see_other, notice: t("transactions.update.success")
    else
      load_form_options
      render :edit, status: :unprocessable_content
    end
  end


  def destroy
    @transaction.destroy
    redirect_to transactions_path, notice: t("transactions.destroy.success")
  end

  private

  def set_transaction
    @transaction = current_account.transactions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to transactions_path, alert: t("transactions.errors.not_found")
  end

  def load_form_options
    @categories = current_account.categories.order(:name)
    @cost_centers = current_account.cost_centers.order(:name)
    @bank_accounts = current_account.bank_accounts.order(:name)
    @credit_cards = current_account.credit_cards.order(:name)
  end

  def transaction_params
    params.require(:transaction).permit(
      :transaction_type,
      :description,
      :amount,
      :date,
      :category_id,
      :cost_center_id,
      :bank_account_id,
      :credit_card_id
    )
  end
end
