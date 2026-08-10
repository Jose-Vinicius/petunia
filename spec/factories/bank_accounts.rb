FactoryBot.define do
  factory :bank_account do
    sequence(:name) { |n| "Conta Bancária #{n}" }
    account
  end
end
