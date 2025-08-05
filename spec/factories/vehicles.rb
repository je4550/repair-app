FactoryBot.define do
  factory :vehicle do
    customer { nil }
    vin { "MyString" }
    make { "MyString" }
    model { "MyString" }
    year { 1 }
    mileage { 1 }
    license_plate { "MyString" }
    color { "MyString" }
    notes { "MyText" }
    deleted_at { "2025-08-04 20:03:35" }
  end
end
