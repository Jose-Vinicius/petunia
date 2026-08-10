FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Categoria #{n}" }
    default { false }
    association :account
  end
end
