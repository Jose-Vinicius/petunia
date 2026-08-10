FactoryBot.define do
  factory :transaction do
    transaction_type { "expense" }
    amount { 150.50 }
    sequence(:description) { |n| "Transação #{n}" }
    date { Date.current }
    association :account
    association :category, factory: :category
    association :bank_account, factory: :bank_account

    before(:create) do |transaction|
      transaction.category.account = transaction.account if transaction.category
      transaction.cost_center.account = transaction.account if transaction.cost_center
      transaction.bank_account.account = transaction.account if transaction.bank_account
      transaction.credit_card.account = transaction.account if transaction.credit_card
    end

    trait :income do
      transaction_type { "income" }
    end

    trait :expense do
      transaction_type { "expense" }
    end

    trait :with_credit_card do
      bank_account { nil }
      association :credit_card, factory: :credit_card
    end
  end
end
