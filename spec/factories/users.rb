FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "usuario#{n}@petunia.local" }
    password { "senha123" }
    password_confirmation { "senha123" }
  end
end
