class AccountUser < ApplicationRecord
  ROLES = %w[owner member].freeze

  belongs_to :user
  belongs_to :account

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :account_id }
end
