FactoryBot.define do
  factory :supplier do
    sequence(:name) { |n| "Fornecedor #{n}" }
    association :account
  end
end
