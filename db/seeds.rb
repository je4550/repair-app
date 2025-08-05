# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data (be careful in production!)
if Rails.env.development?
  puts "Clearing existing data..."
  # Temporarily disable foreign key constraints for SQLite
  ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF") if ActiveRecord::Base.connection.adapter_name == 'SQLite'
  
  # Clear all tables directly
  ActiveRecord::Base.connection.execute("DELETE FROM service_reminders")
  ActiveRecord::Base.connection.execute("DELETE FROM communications")
  ActiveRecord::Base.connection.execute("DELETE FROM reviews")
  ActiveRecord::Base.connection.execute("DELETE FROM appointment_services")
  ActiveRecord::Base.connection.execute("DELETE FROM appointments")
  ActiveRecord::Base.connection.execute("DELETE FROM vehicles")
  ActiveRecord::Base.connection.execute("DELETE FROM customers")
  ActiveRecord::Base.connection.execute("DELETE FROM services")
  ActiveRecord::Base.connection.execute("DELETE FROM users")
  ActiveRecord::Base.connection.execute("DELETE FROM shops")
  
  # Re-enable foreign key constraints
  ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON") if ActiveRecord::Base.connection.adapter_name == 'SQLite'
end

# Create demo shop: Jeff's Automotive
puts "Creating Jeff's Automotive shop..."
jeffs_shop = Shop.create!(
  name: "Jeff's Automotive",
  subdomain: "jeffs",
  owner_name: "Jeff Thompson",
  phone: "555-123-4567",
  email: "jeff@jeffsautomotive.com",
  address_line1: "202 South St",
  city: "Rochester",
  state: "MI",
  zip: "48307",
  active: true
)

# Set current tenant for seeding
ActsAsTenant.current_tenant = jeffs_shop

# Create users for Jeff's Automotive
puts "Creating users..."
admin_user = User.create!(
  email: "admin@jeffsautomotive.com",
  password: "password123",
  first_name: "Jeff",
  last_name: "Thompson",
  phone: "555-123-4567",
  role: "admin",
  shop: jeffs_shop
)

manager_user = User.create!(
  email: "manager@jeffsautomotive.com",
  password: "password123",
  first_name: "Sarah",
  last_name: "Johnson",
  phone: "555-123-4568",
  role: "manager",
  shop: jeffs_shop
)

technician1 = User.create!(
  email: "tech1@jeffsautomotive.com",
  password: "password123",
  first_name: "Mike",
  last_name: "Wilson",
  phone: "555-123-4569",
  role: "technician",
  shop: jeffs_shop
)

technician2 = User.create!(
  email: "tech2@jeffsautomotive.com",
  password: "password123",
  first_name: "Tom",
  last_name: "Davis",
  phone: "555-123-4570",
  role: "technician",
  shop: jeffs_shop
)

receptionist = User.create!(
  email: "reception@jeffsautomotive.com",
  password: "password123",
  first_name: "Emily",
  last_name: "Brown",
  phone: "555-123-4571",
  role: "receptionist",
  shop: jeffs_shop
)

# Create additional services beyond the defaults
puts "Creating additional services..."
services = [
  { name: "Brake Pad Replacement", description: "Replace front or rear brake pads", price: 149.99, duration_minutes: 60 },
  { name: "Transmission Fluid Change", description: "Drain and refill transmission fluid", price: 89.99, duration_minutes: 45 },
  { name: "Coolant Flush", description: "Flush cooling system and refill with fresh coolant", price: 79.99, duration_minutes: 30 },
  { name: "Air Filter Replacement", description: "Replace engine air filter", price: 29.99, duration_minutes: 10 },
  { name: "Cabin Air Filter Replacement", description: "Replace cabin air filter", price: 39.99, duration_minutes: 15 },
  { name: "Spark Plug Replacement", description: "Replace spark plugs", price: 119.99, duration_minutes: 45 },
  { name: "Wheel Alignment", description: "Four wheel alignment", price: 89.99, duration_minutes: 60 },
  { name: "AC Service", description: "AC system inspection and recharge", price: 129.99, duration_minutes: 45 },
  { name: "Engine Diagnostic", description: "Computer diagnostic scan", price: 59.99, duration_minutes: 30 },
  { name: "Fuel System Cleaning", description: "Clean fuel injectors and system", price: 99.99, duration_minutes: 30 }
]

services.each do |service_attrs|
  jeffs_shop.services.create!(service_attrs)
end

# Create customers with vehicles
puts "Creating customers and vehicles..."
customers_data = [
  {
    customer: { first_name: "John", last_name: "Smith", email: "john.smith@email.com", phone: "555-234-5678", 
                address_line1: "123 Main St", city: "Rochester", state: "MI", zip: "48307" },
    vehicles: [
      { make: "Toyota", model: "Prius", year: 2019, vin: "JTDKN3DU0A0000001", license_plate: "ABC123", mileage: 63120 }
    ]
  },
  {
    customer: { first_name: "Mary", last_name: "Johnson", email: "mary.johnson@email.com", phone: "555-345-6789",
                address_line1: "456 Oak Ave", city: "Rochester", state: "MI", zip: "48307" },
    vehicles: [
      { make: "Ford", model: "F-150", year: 2018, vin: "1FTFW1ET5JFC00001", license_plate: "XYZ789", mileage: 71120 },
      { make: "Honda", model: "Civic", year: 2020, vin: "19XFC2F59LE000001", license_plate: "DEF456", mileage: 25500 }
    ]
  },
  {
    customer: { first_name: "Robert", last_name: "Williams", email: "robert.williams@email.com", phone: "555-456-7890",
                address_line1: "789 Elm St", city: "Rochester", state: "MI", zip: "48308" },
    vehicles: [
      { make: "Chevrolet", model: "Silverado", year: 2017, vin: "1GCVKREC0HZ000001", license_plate: "GHI789", mileage: 87476 }
    ]
  },
  {
    customer: { first_name: "Patricia", last_name: "Brown", email: "patricia.brown@email.com", phone: "555-567-8901",
                address_line1: "321 Pine Rd", city: "Rochester", state: "MI", zip: "48309" },
    vehicles: [
      { make: "Nissan", model: "Altima", year: 2019, vin: "1N4BL4BV6KC000001", license_plate: "JKL012", mileage: 42000 }
    ]
  },
  {
    customer: { first_name: "Michael", last_name: "Davis", email: "michael.davis@email.com", phone: "555-678-9012",
                address_line1: "654 Maple Dr", city: "Rochester", state: "MI", zip: "48307" },
    vehicles: [
      { make: "BMW", model: "330i", year: 2020, vin: "WBA5R1C50LA000001", license_plate: "MNO345", mileage: 18500 }
    ]
  },
  {
    customer: { first_name: "Jennifer", last_name: "Garcia", email: "jennifer.garcia@email.com", phone: "555-789-0123",
                address_line1: "987 Cedar Ln", city: "Rochester", state: "MI", zip: "48308" },
    vehicles: [
      { make: "Tesla", model: "Model 3", year: 2021, vin: "5YJ3E1EA1MF000001", license_plate: "PQR678", mileage: 12000 }
    ]
  },
  {
    customer: { first_name: "William", last_name: "Rodriguez", email: "william.rodriguez@email.com", phone: "555-890-1234",
                address_line1: "147 Birch Way", city: "Rochester", state: "MI", zip: "48309" },
    vehicles: [
      { make: "Jeep", model: "Grand Cherokee", year: 2018, vin: "1C4RJFBG5JC000001", license_plate: "STU901", mileage: 54300 }
    ]
  },
  {
    customer: { first_name: "Elizabeth", last_name: "Martinez", email: "elizabeth.martinez@email.com", phone: "555-901-2345",
                address_line1: "258 Spruce St", city: "Rochester", state: "MI", zip: "48307" },
    vehicles: [
      { make: "Subaru", model: "Outback", year: 2019, vin: "4S4BSAFC0K3000001", license_plate: "VWX234", mileage: 35600 }
    ]
  },
  {
    customer: { first_name: "David", last_name: "Anderson", email: "david.anderson@email.com", phone: "555-012-3456",
                address_line1: "369 Willow Ct", city: "Rochester", state: "MI", zip: "48308" },
    vehicles: [
      { make: "Volkswagen", model: "Jetta", year: 2020, vin: "3VWN57BU0LM000001", license_plate: "YZA567", mileage: 28900 }
    ]
  },
  {
    customer: { first_name: "Barbara", last_name: "Thomas", email: "barbara.thomas@email.com", phone: "555-123-4567",
                address_line1: "741 Ash Blvd", city: "Rochester", state: "MI", zip: "48309" },
    vehicles: [
      { make: "FIAT", model: "500", year: 2015, vin: "3C3CFFBR6FT000001", license_plate: "BCD890", mileage: 87674, 
        notes: "Customer mentioned slight vibration when braking" }
    ]
  }
]

created_customers = []
customers_data.each do |data|
  customer = Customer.create!(data[:customer].merge(shop: jeffs_shop))
  data[:vehicles].each do |vehicle_attrs|
    customer.vehicles.create!(vehicle_attrs)
  end
  created_customers << customer
end

# Create past appointments with services
puts "Creating appointment history..."
oil_change = jeffs_shop.services.find_by(name: "Oil Change")
tire_rotation = jeffs_shop.services.find_by(name: "Tire Rotation")
brake_inspection = jeffs_shop.services.find_by(name: "Brake Inspection")
brake_replacement = jeffs_shop.services.find_by(name: "Brake Pad Replacement")
air_filter = jeffs_shop.services.find_by(name: "Air Filter Replacement")

# Create completed appointments for history
created_customers.each_with_index do |customer, index|
  vehicle = customer.vehicles.first
  
  # Create 2-3 past appointments per customer
  (2..3).to_a.sample.times do |i|
    appointment_date = (i + 1).months.ago + index.days
    appointment = customer.appointments.create!(
      vehicle: vehicle,
      scheduled_at: appointment_date,
      status: 'completed',
      notes: "Regular maintenance visit"
    )
    
    # Add services to appointment
    appointment.add_service(oil_change)
    appointment.add_service(tire_rotation) if [true, false].sample
    appointment.add_service(brake_inspection) if i == 0
    
    appointment.calculate_total_price!
    
    # Add a review for some appointments
    if [true, false].sample
      appointment.create_review!(
        customer: customer,
        rating: [4, 5, 5, 5].sample,
        comment: ["Great service as always!", "Quick and professional", "Very satisfied with the work", ""].sample,
        source: 'internal'
      )
    end
  end
end

# Create upcoming appointments
puts "Creating upcoming appointments..."
upcoming_customers = created_customers.sample(5)
upcoming_customers.each_with_index do |customer, index|
  vehicle = customer.vehicles.first
  appointment_time = index.days.from_now + (9 + index).hours
  
  appointment = customer.appointments.create!(
    vehicle: vehicle,
    scheduled_at: appointment_time,
    status: ['scheduled', 'confirmed'].sample,
    notes: "Scheduled maintenance"
  )
  
  # Add services
  appointment.add_service(oil_change)
  if vehicle.mileage > 60000
    appointment.add_service(brake_replacement)
  end
  appointment.calculate_total_price!
end

# Create service reminders
puts "Creating service reminders..."
created_customers.each do |customer|
  vehicle = customer.vehicles.first
  
  # Oil change reminder
  ServiceReminder.create!(
    customer: customer,
    vehicle: vehicle,
    service: oil_change,
    reminder_type: 'time',
    scheduled_date: 3.months.from_now,
    status: 'pending'
  )
  
  # Tire rotation reminder for some
  if vehicle.mileage > 50000
    ServiceReminder.create!(
      customer: customer,
      vehicle: vehicle,
      service: tire_rotation,
      reminder_type: 'mileage',
      scheduled_date: 2.months.from_now,
      status: 'pending'
    )
  end
end

# Create some communications
puts "Creating communication history..."
created_customers.sample(6).each do |customer|
  # Welcome email
  customer.communications.create!(
    communication_type: 'email',
    subject: 'Welcome to Jeff\'s Automotive!',
    content: 'Thank you for choosing Jeff\'s Automotive for your vehicle service needs.',
    status: 'delivered',
    sent_at: 2.weeks.ago
  )
  
  # Appointment reminder SMS
  customer.communications.create!(
    communication_type: 'sms',
    subject: 'Appointment Reminder',
    content: 'Reminder: You have an appointment at Jeff\'s Automotive tomorrow at 10 AM.',
    status: 'delivered',
    sent_at: 1.day.ago
  )
end

puts "\n=== Seeding Complete! ==="
puts "Shop created: #{jeffs_shop.name} (subdomain: #{jeffs_shop.subdomain})"
puts "Users created: #{User.count}"
puts "Customers created: #{Customer.count}"
puts "Vehicles created: #{Vehicle.count}"
puts "Services available: #{Service.count}"
puts "Appointments created: #{Appointment.count}"
puts "Reviews created: #{Review.count}"
puts "Service reminders created: #{ServiceReminder.count}"
puts "Communications sent: #{Communication.count}"
puts "\nYou can now sign in at http://jeffs.localhost:3000"
puts "Admin login: admin@jeffsautomotive.com / password123"