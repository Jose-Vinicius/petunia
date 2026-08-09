FactoryBot.define do
  factory :account_user do
    user
    account
    role { "owner" }
  end
end
