class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :account_users, dependent: :destroy
  has_many :accounts, through: :account_users

  after_create :create_default_account

  private

  def create_default_account
    account = Account.create!(name: "Conta Pessoal")
    account_users.create!(account: account, role: "owner")
  end
end
