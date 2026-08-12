class CreditCardInvoicePayment < ApplicationRecord
  belongs_to :account
  belongs_to :credit_card
  belongs_to :bank_account
  belongs_to :bank_transaction, class_name: "Transaction", foreign_key: "transaction_id", optional: true, dependent: :destroy

  validates :competence_date, :amount, :paid_at, presence: true
  validates :amount, numericality: { greater_than: 0 }

  scope :for_month, ->(date) { where(competence_date: date.beginning_of_month..date.end_of_month) }

  def amount=(val)
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
end
