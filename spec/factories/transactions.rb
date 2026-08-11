FactoryBot.define do
  factory :transaction do
    transaction_type { "expense" }
    amount { 150.50 }
    sequence(:description) { |n| "Transação #{n}" }
    date { Date.current }
    association :account
    category { association :category, account: account }
    supplier { association :supplier, account: account }
    bank_account { association :bank_account, account: account }

    trait :income do
      transaction_type { "income" }
    end

    trait :expense do
      transaction_type { "expense" }
    end

    trait :with_credit_card do
      bank_account { nil }
      credit_card { association :credit_card, account: account }
    end
  end
end
