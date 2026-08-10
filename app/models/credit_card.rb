class CreditCard < ApplicationRecord
  belongs_to :bank_account
  belongs_to :account

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :limit, presence: true, numericality: { greater_than_or_equal_to: 0 }

  validate :bank_account_belongs_to_same_account

  private

  def bank_account_belongs_to_same_account
    return if bank_account.nil? || account_id.nil?

    if bank_account.account_id != account_id
      errors.add(:bank_account, :invalid)
    end
  end
end
