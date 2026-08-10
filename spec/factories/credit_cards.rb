FactoryBot.define do
  factory :credit_card do
    sequence(:name) { |n| "Cartão #{n}" }
    limit { 5000.00 }
    account { bank_account.account }
    bank_account
  end
end
