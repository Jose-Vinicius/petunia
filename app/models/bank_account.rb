class BankAccount < ApplicationRecord
  belongs_to :account
  has_many :credit_cards, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :incoming_transfers, class_name: "Transaction", foreign_key: :destination_bank_account_id, dependent: :nullify


  validates :name, presence: true, uniqueness: { scope: :account_id }
end
