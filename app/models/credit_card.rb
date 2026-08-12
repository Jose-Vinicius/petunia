class CreditCard < ApplicationRecord
  belongs_to :bank_account
  belongs_to :account
  has_many :transactions, dependent: :destroy


  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :limit, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :closing_day, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 31 }
  validates :due_day, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 31 }

  validate :bank_account_belongs_to_same_account

  def limit=(val)
    if val.is_a?(String)
      str = val.strip.gsub(/[R$\s]/, "")
      parsed = if str.include?(",") && str.include?(".")
                 str.tr(".", "").tr(",", ".").to_f
               elsif str.include?(",")
                 str.tr(",", ".").to_f
               else
                 str.to_f
               end
      super(parsed)
    else
      super(val)
    end
  end

  def invoice_competence_for(transaction_date)
    return transaction_date.to_date if closing_day.blank? || due_day.blank?

    t_date = transaction_date.to_date
    if t_date.day > closing_day
      closing_month = t_date.beginning_of_month.next_month
    else
      closing_month = t_date.beginning_of_month
    end

    due_month = due_day <= closing_day ? closing_month.next_month : closing_month
    max_day = due_month.end_of_month.day
    target_day = [due_day, max_day].min

    Date.new(due_month.year, due_month.month, target_day)
  end

  has_many :invoice_payments, class_name: "CreditCardInvoicePayment", dependent: :destroy

  def invoice_paid_for?(month_date)
    return false if month_date.blank?
    start_date = month_date.to_date.beginning_of_month
    end_date = month_date.to_date.end_of_month
    invoice_payments.where(competence_date: start_date..end_date).exists?
  end

  def invoice_payment_for(month_date)
    return nil if month_date.blank?
    start_date = month_date.to_date.beginning_of_month
    end_date = month_date.to_date.end_of_month
    invoice_payments.find_by(competence_date: start_date..end_date)
  end

  def spent_unpaid
    paid_competences = invoice_payments.pluck(:competence_date).map { |d| d.beginning_of_month }.uniq
    charges_txs = transactions.expense.charges.to_a
    if paid_competences.present?
      unpaid = charges_txs.reject { |tx| tx.competence_date.present? && paid_competences.include?(tx.competence_date.beginning_of_month) }
      unpaid.sum(&:amount)
    else
      charges_txs.sum(&:amount)
    end
  end

  private

  def bank_account_belongs_to_same_account
    return if bank_account.nil? || account_id.nil?

    if bank_account.account_id != account_id
      errors.add(:bank_account, :invalid)
    end
  end
end
