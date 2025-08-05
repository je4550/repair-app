FactoryBot.define do
  factory :review do
    customer { nil }
    appointment { nil }
    rating { 1 }
    comment { "MyText" }
    source { "MyString" }
    review_date { "2025-08-04 20:03:59" }
  end
end
