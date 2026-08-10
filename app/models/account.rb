class Account < ApplicationRecord
  has_many :account_users, dependent: :destroy
  has_many :users, through: :account_users
  has_many :bank_accounts, dependent: :destroy
  has_many :credit_cards, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :cost_centers, dependent: :destroy
  has_many :transactions, dependent: :destroy


  validates :name, presence: true

  after_create :seed_default_categories_and_cost_centers

  private

  def seed_default_categories_and_cost_centers
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
  end
end
