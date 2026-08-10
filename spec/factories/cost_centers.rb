FactoryBot.define do
  factory :cost_center do
    sequence(:name) { |n| "Centro de Custo #{n}" }
    default { false }
    association :account
  end
end
