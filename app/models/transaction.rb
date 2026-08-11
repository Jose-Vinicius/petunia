class Transaction < ApplicationRecord
  enum :transaction_type, { income: "income", expense: "expense" }

  belongs_to :account
  belongs_to :category
  belongs_to :supplier
  belongs_to :cost_center, optional: true
  belongs_to :bank_account, optional: true
  belongs_to :credit_card, optional: true

  validates :description, :date, :amount, :transaction_type, :supplier_id, presence: true
  validates :amount, numericality: { greater_than: 0 }

  validate :must_have_valid_payment_source
  validate :same_account_associations

  def payment_source_name
    if bank_account.present?
      bank_account.name
    elsif credit_card.present?
      credit_card.name
    else
      "-"
    end
  end

  private

  def must_have_valid_payment_source
    if income? && bank_account_id.blank?
      errors.add(:bank_account_id, "é obrigatória para lançamentos de receita")
    elsif expense? && bank_account_id.blank? && credit_card_id.blank?
      errors.add(:base, "Informe uma Conta Bancária ou um Cartão de Crédito como forma de pagamento")
    elsif income? && credit_card_id.present?
      errors.add(:credit_card_id, "não pode ser utilizado para lançamentos de receita")
    end
  end

  def same_account_associations
    return unless account_id

    errors.add(:category, "inválida para esta conta") if category && category.account_id != account_id
    errors.add(:supplier, "inválido para esta conta") if supplier && supplier.account_id != account_id
    errors.add(:cost_center, "inválido para esta conta") if cost_center && cost_center.account_id != account_id
    errors.add(:bank_account, "inválida para esta conta") if bank_account && bank_account.account_id != account_id
    errors.add(:credit_card, "inválido para esta conta") if credit_card && credit_card.account_id != account_id
  end
end
