class Account < ApplicationRecord
  has_many :account_users, dependent: :destroy
  has_many :users, through: :account_users
  has_many :bank_accounts, dependent: :destroy
  has_many :credit_cards, dependent: :destroy

  validates :name, presence: true
end
