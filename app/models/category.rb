class Category < ApplicationRecord
  DEFAULT_CATEGORIES = [
    "Alimentação",
    "Moradia",
    "Transporte",
    "Lazer",
    "Saúde",
    "Educação",
    "Salário"
  ].freeze

  belongs_to :account

  validates :name, presence: true, uniqueness: { scope: :account_id, case_sensitive: false }
end
