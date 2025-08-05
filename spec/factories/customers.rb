FactoryBot.define do
  factory :customer do
    first_name { "MyString" }
    last_name { "MyString" }
    email { "MyString" }
    phone { "MyString" }
    address_line1 { "MyString" }
    address_line2 { "MyString" }
    city { "MyString" }
    state { "MyString" }
    zip { "MyString" }
    notes { "MyText" }
    deleted_at { "2025-08-04 20:03:30" }
  end
end
