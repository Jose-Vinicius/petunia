class CreditCardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_credit_card, only: [ :edit, :update, :destroy, :invoices, :pay_invoice, :unpay_invoice ]

  def index
    scope = current_account.credit_cards.includes(:bank_account)
    scope = scope.where("LOWER(name) LIKE ?", "%#{params[:search].downcase.strip}%") if params[:search].present?
    @credit_cards = scope.order(:name)
  end

  def new
    @credit_card = current_account.credit_cards.build(closing_day: 25, due_day: 5)
  end

  def create
    @credit_card = current_account.credit_cards.build(credit_card_params)

    if @credit_card.save
      redirect_to credit_cards_path, notice: t("credit_cards.create.success", name: @credit_card.name)
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @credit_card.update(credit_card_params)
      redirect_to credit_cards_path, notice: t("credit_cards.update.success", name: @credit_card.name)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @credit_card.destroy
    redirect_to credit_cards_path, notice: t("credit_cards.destroy.success", name: @credit_card.name)
  end

  def invoices
    @selected_month = params[:month].present? ? (Date.parse("#{params[:month]}-01") rescue Date.current) : Date.current
    start_of_month = @selected_month.beginning_of_month
    end_of_month = @selected_month.end_of_month

    @transactions = @credit_card.transactions
                                 .includes(:category, :supplier, :cost_center)
                                 .where(competence_date: start_of_month..end_of_month)
                                 .order(date: :desc)

    @refunds_total = @transactions.expense.refunds.sum(:amount)
    @charges_total = @transactions.expense.charges.sum(:amount) + @refunds_total
    @invoice_total = @charges_total - @refunds_total
    @bank_accounts = current_account.bank_accounts.order(:name)
    @invoice_payment = @credit_card.invoice_payment_for(@selected_month)
    @is_paid = @invoice_payment.present?
  end

  def pay_invoice
    month_str = params[:month]
    selected_month = month_str.present? ? (Date.parse("#{month_str}-01") rescue Date.current) : Date.current

    raw_amount = params[:amount].to_s.strip.gsub(/[R$\s]/, "")
    amount = (raw_amount.include?(",") ? raw_amount.tr(".", "").tr(",", ".") : raw_amount).to_f.abs
    payment_date = params[:payment_date].presence ? (Date.parse(params[:payment_date]) rescue Date.current) : Date.current
    bank_account = current_account.bank_accounts.find_by(id: params[:bank_account_id])

    if bank_account.blank? || amount <= 0
      redirect_to invoices_credit_card_path(@credit_card, month: month_str), alert: "Selecione uma conta bancária e um valor válido."
      return
    end

    category = current_account.categories.find_by("LOWER(name) = ?", "pagamento de fatura") ||
               current_account.categories.create!(name: "Pagamento de Fatura")
    supplier = current_account.suppliers.find_by("LOWER(name) = ?", @credit_card.name.downcase) ||
               current_account.suppliers.create!(name: @credit_card.name)

    month_fmt = l(selected_month, format: "%B/%Y") rescue month_str

    ActiveRecord::Base.transaction do
      tx = current_account.transactions.create!(
        transaction_type: "expense",
        description: "Pagamento Fatura #{@credit_card.name} (#{month_fmt})",
        amount: amount,
        date: payment_date,
        bank_account: bank_account,
        category: category,
        supplier: supplier,
        status: "realized"
      )

      current_account.credit_card_invoice_payments.create!(
        credit_card: @credit_card,
        bank_account: bank_account,
        bank_transaction: tx,
        competence_date: selected_month.beginning_of_month,
        amount: amount,
        paid_at: payment_date
      )
    end

    redirect_to invoices_credit_card_path(@credit_card, month: month_str), notice: "Pagamento da fatura registrado com sucesso! Limite do cartão liberado."
  rescue StandardError => e
    redirect_to invoices_credit_card_path(@credit_card, month: month_str), alert: "Erro ao registrar pagamento: #{e.message}"
  end

  def unpay_invoice
    month_str = params[:month]
    selected_month = month_str.present? ? (Date.parse("#{month_str}-01") rescue Date.current) : Date.current
    payment = @credit_card.invoice_payment_for(selected_month)

    if payment.present?
      payment.destroy
      redirect_to invoices_credit_card_path(@credit_card, month: month_str), notice: "Pagamento de fatura desfeito com sucesso! Limite atualizado."
    else
      redirect_to invoices_credit_card_path(@credit_card, month: month_str), alert: "Nenhum pagamento registrado para esta fatura."
    end
  end

  private

  def set_credit_card
    @credit_card = current_account.credit_cards.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to credit_cards_path, alert: t("credit_cards.errors.not_found")
  end

  def credit_card_params
    params.require(:credit_card).permit(:name, :limit, :bank_account_id, :closing_day, :due_day)
  end
end
