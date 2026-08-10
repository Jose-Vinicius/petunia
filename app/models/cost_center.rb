class CostCenter < ApplicationRecord
  DEFAULT_COST_CENTERS = [
    "Pessoal",
    "Trabalho",
    "Projetos"
  ].freeze

  belongs_to :account
  has_many :transactions, dependent: :nullify


  validates :name, presence: true, uniqueness: { scope: :account_id, case_sensitive: false }
end
