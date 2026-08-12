class Account < ApplicationRecord
  has_many :account_users, dependent: :destroy
  has_many :users, through: :account_users
  has_many :bank_accounts, dependent: :destroy
  has_many :credit_cards, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :cost_centers, dependent: :destroy
  has_many :suppliers, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :credit_card_invoice_payments, dependent: :destroy


  validates :name, presence: true

  after_create :seed_defaults

  def reset_data!
    transaction do
      credit_card_invoice_payments.destroy_all
      transactions.destroy_all
      credit_cards.destroy_all
      bank_accounts.destroy_all
      categories.destroy_all
      cost_centers.destroy_all
      suppliers.destroy_all

      seed_defaults
    end
  end

  private

  def seed_defaults
    Category::DEFAULT_CATEGORIES.each do |cat_name|
      categories.find_or_create_by!(name: cat_name) do |cat|
        cat.default = true
      end
    end

    CostCenter::DEFAULT_COST_CENTERS.each do |cc_name|
      cost_centers.find_or_create_by!(name: cc_name) do |cc|
        cc.default = true
      end
    end

    Supplier::DEFAULT_SUPPLIERS.each do |sup_name|
      suppliers.find_or_create_by!(name: sup_name)
    end
  end
end
