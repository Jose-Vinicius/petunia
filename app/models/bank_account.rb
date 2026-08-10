class BankAccount < ApplicationRecord
  belongs_to :account
  has_many :credit_cards, dependent: :destroy
  has_many :transactions, dependent: :destroy


  validates :name, presence: true, uniqueness: { scope: :account_id }
end
