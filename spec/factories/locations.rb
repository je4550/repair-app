FactoryBot.define do
  factory :location do
    name { "MyString" }
    address { "MyText" }
    city { "MyString" }
    state { "MyString" }
    zip { "MyString" }
    phone { "MyString" }
    region { nil }
    deleted_at { "2025-08-04 23:35:58" }
  end
end
