FactoryBot.define do
  factory :communication do
    customer { nil }
    communication_type { "MyString" }
    subject { "MyString" }
    content { "MyText" }
    sent_at { "2025-08-04 20:03:55" }
    status { "MyString" }
  end
end
