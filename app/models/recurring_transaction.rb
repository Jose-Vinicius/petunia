class RecurringTransaction < ApplicationRecord
  belongs_to :account
  belongs_to :category
  belongs_to :supplier, optional: true
  belongs_to :cost_center, optional: true
  belongs_to :bank_account, optional: true
  belongs_to :credit_card, optional: true

  has_many :transactions, dependent: :nullify

  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_type, presence: true, inclusion: { in: %w[expense income] }
  validates :frequency, presence: true, inclusion: { in: %w[monthly yearly] }
  validates :start_date, presence: true

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

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

  def income?
    transaction_type == "income"
  end

  def expense?
    transaction_type == "expense"
  end

  def reimbursable?
    has_attribute?(:reimbursable) ? super : false
  end

  def reimbursed?
    has_attribute?(:reimbursed) ? super : false
  end

  def toggle_active!
    update!(active: !active)
  end
end
