class Supplier < ApplicationRecord
  DEFAULT_SUPPLIERS = [ "Geral" ].freeze

  belongs_to :account
  has_many :transactions, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :account_id, case_sensitive: false }
end
