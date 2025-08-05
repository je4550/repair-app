FactoryBot.define do
  factory :service_reminder do
    customer { nil }
    vehicle { nil }
    service { nil }
    reminder_type { "MyString" }
    scheduled_date { "2025-08-04" }
    status { "MyString" }
    sent_at { "2025-08-04 20:04:04" }
  end
end
