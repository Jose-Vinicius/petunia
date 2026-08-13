class RecurrencesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recurring_transaction, only: %i[show edit update destroy toggle_active]
  before_action :load_form_options, only: %i[new edit create update]

  def index
    @recurring_transactions = current_account.recurring_transactions
                                            .includes(:category, :supplier, :cost_center, :bank_account, :credit_card)
                                            .order(created_at: :desc)
  end

  def show
    @transactions = @recurring_transaction.transactions.order(date: :asc)
  end

  def new
    @recurring_transaction = current_account.recurring_transactions.build(
      frequency: "monthly",
      start_date: Date.current
    )
  end

  def create
    creator = RecurringTransactionCreator.new(
      account: current_account,
      base_params: recurring_params.to_h,
      amount: recurring_params[:amount],
      months_count: params[:recurring_months_count].presence || 12,
      frequency: recurring_params[:frequency] || "monthly"
    )
    txs = creator.call

    if txs.present?
      redirect_to recurrences_path, notice: "Recorrência cadastrada e #{txs.size} lançamentos projetados!"
    else
      @recurring_transaction = current_account.recurring_transactions.build(recurring_params)
      @recurring_transaction.errors.add(:base, "Não foi possível criar a recorrência. Verifique os dados.")
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    old_amount = @recurring_transaction.amount

    if @recurring_transaction.update(recurring_params)
      # If amount changed, update future pending transactions
      if old_amount != @recurring_transaction.amount
        @recurring_transaction.transactions.pending.where("date >= ?", Date.current).update_all(amount: @recurring_transaction.amount)
      end

      redirect_to recurrences_path, notice: "Recorrência atualizada com sucesso!"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def toggle_active
    @recurring_transaction.toggle_active!
    status_text = @recurring_transaction.active? ? "ativada" : "pausada"
    redirect_to recurrences_path, notice: "Recorrência #{status_text} com sucesso!"
  end

  def destroy
    ActiveRecord::Base.transaction do
      # Remove future pending transactions associated with this rule
      @recurring_transaction.transactions.pending.where("date >= ?", Date.current).destroy_all
      @recurring_transaction.destroy
    end

    redirect_to recurrences_path, notice: "Recorrência e lançamentos pendentes futuros removidos com sucesso!"
  end

  private

  def set_recurring_transaction
    @recurring_transaction = current_account.recurring_transactions.find(params[:id])
  end

  def recurring_params
    params.require(:recurring_transaction).permit(
      :description, :amount, :transaction_type, :frequency, :start_date, :end_date,
      :category_id, :supplier_id, :cost_center_id, :bank_account_id, :credit_card_id,
      :is_refund, :active
    )
  end

  def load_form_options
    @categories = current_account.categories.order(:name)
    @suppliers = current_account.suppliers.order(:name)
    @cost_centers = current_account.cost_centers.order(:name)
    @bank_accounts = current_account.bank_accounts.order(:name)
    @credit_cards = current_account.credit_cards.order(:name)
  end
end
