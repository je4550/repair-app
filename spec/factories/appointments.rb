FactoryBot.define do
  factory :appointment do
    customer { nil }
    vehicle { nil }
    scheduled_at { "2025-08-04 20:03:45" }
    status { "MyString" }
    notes { "MyText" }
    total_price { "9.99" }
    deleted_at { "2025-08-04 20:03:45" }
  end
end
