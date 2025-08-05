FactoryBot.define do
  factory :appointment_service do
    appointment { nil }
    service { nil }
    quantity { 1 }
    price { "9.99" }
  end
end
