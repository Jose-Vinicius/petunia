class Transaction < ApplicationRecord
  enum :transaction_type, { income: "income", expense: "expense", transfer: "transfer" }

  belongs_to :account
  belongs_to :category
  belongs_to :supplier
  belongs_to :cost_center, optional: true
  belongs_to :bank_account, optional: true
  belongs_to :credit_card, optional: true
  belongs_to :destination_bank_account, class_name: "BankAccount", optional: true

  scope :charges, -> { where(is_refund: false) }
  scope :refunds, -> { where(is_refund: true) }
  scope :by_group, ->(group_id) { where(installment_group_id: group_id) }
  scope :without_invoice_payments, -> {
    left_joins(:category).where("categories.id IS NULL OR LOWER(categories.name) NOT LIKE ?", "%pagamento%fatura%")
  }

  def installment?
    installment_group_id.present?
  end

  validates :description, :date, :competence_date, :amount, :transaction_type, :supplier_id, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :is_refund, inclusion: { in: [true, false] }

  before_validation :set_default_is_refund
  before_validation :set_default_competence_date

  validate :must_have_valid_payment_source
  validate :same_account_associations
  validate :refund_only_allowed_on_credit_cards

  def payment_source_name
    if bank_account.present?
      bank_account.name
    elsif credit_card.present?
      credit_card.name
    else
      "-"
    end
  end

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

  def is_refund?
    has_attribute?(:is_refund) ? super : false
  end

  private

  def set_default_is_refund
    return unless has_attribute?(:is_refund)
    self.is_refund = false if self.is_refund.nil?
  end

  def set_default_competence_date
    return unless date.present?
    return unless new_record?
    return if competence_date.present?

    if credit_card.present?
      self.competence_date = credit_card.invoice_competence_for(date)
    else
      self.competence_date = date
    end
  end

  def must_have_valid_payment_source
    if income? && bank_account_id.blank?
      errors.add(:bank_account_id, "é obrigatória para lançamentos de receita")
    elsif expense? && bank_account_id.blank? && credit_card_id.blank?
      errors.add(:base, "Informe uma Conta Bancária ou um Cartão de Crédito como forma de pagamento")
    elsif income? && credit_card_id.present?
      errors.add(:credit_card_id, "não pode ser utilizado para lançamentos de receita")
    elsif transfer?
      if bank_account_id.blank? && credit_card_id.blank?
        errors.add(:base, "Informe uma Conta Bancária ou Cartão de Crédito de origem para a transferência")
      end
      if destination_bank_account_id.blank?
        errors.add(:destination_bank_account_id, "é obrigatória para transferências")
      end
      if bank_account_id.present? && destination_bank_account_id.present? && bank_account_id == destination_bank_account_id
        errors.add(:destination_bank_account_id, "deve ser diferente da conta de origem")
      end
    end
  end

  def same_account_associations
    return unless account_id

    errors.add(:category, "inválida para esta conta") if category && category.account_id != account_id
    errors.add(:supplier, "inválido para esta conta") if supplier && supplier.account_id != account_id
    errors.add(:cost_center, "inválido para esta conta") if cost_center && cost_center.account_id != account_id
    errors.add(:bank_account, "inválida para esta conta") if bank_account && bank_account.account_id != account_id
    errors.add(:credit_card, "inválido para esta conta") if credit_card && credit_card.account_id != account_id
    errors.add(:destination_bank_account, "inválida para esta conta") if destination_bank_account && destination_bank_account.account_id != account_id
  end

  def refund_only_allowed_on_credit_cards
    return if transfer?

    if is_refund? && credit_card_id.blank?
      errors.add(:is_refund, "só pode ser aplicado em lançamentos de cartão de crédito")
    end
  end
end
