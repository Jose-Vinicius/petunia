FactoryBot.define do
  factory :account do
    sequence(:name) { |n| "Conta #{n}" }
  end
end
