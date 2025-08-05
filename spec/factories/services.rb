FactoryBot.define do
  factory :service do
    name { "MyString" }
    description { "MyText" }
    price { "9.99" }
    duration_minutes { 1 }
    active { false }
    deleted_at { "2025-08-04 20:03:40" }
  end
end
