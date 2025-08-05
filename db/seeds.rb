# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Wrap everything in without_tenant to avoid tenant issues during seeding
ActsAsTenant.without_tenant do
  # Clear existing data (be careful in production!)
  if Rails.env.development?
    puts "Clearing existing data..."
    # Clear all tables directly (order matters due to foreign keys)
    tables = %w[
      service_reminders
      communications
      reviews
      appointment_services
      appointments
      vehicles
      customers
      services
      users
      locations
      regions
      shops
    ]
    
    tables.each do |table|
      if ActiveRecord::Base.connection.table_exists?(table)
        ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
      end
    end
  end

  # Create demo shop: Jeff's Automotive
  puts "Creating or finding Jeff's Automotive shop..."
  jeffs_shop = Shop.find_or_create_by!(subdomain: "jeffs") do |shop|
    shop.name = "Jeff's Automotive"
    shop.owner_name = "Jeff Thompson"
    shop.phone = "555-123-4567"
    shop.email = "jeff@jeffsautomotive.com"
    shop.address_line1 = "202 South St"
    shop.city = "Rochester"
    shop.state = "MI"
    shop.zip = "48307"
    shop.active = true
  end

# Create region and location for Jeff's Automotive
puts "Creating or finding region and location..."
rochester_region = Region.find_or_create_by!(shop: jeffs_shop, name: "Rochester")

main_location = Location.find_or_create_by!(region: rochester_region, name: "Main Location") do |location|
  location.address_line1 = "202 South St"
  location.city = "Rochester"
  location.state = "MI"
  location.zip = "48307"
  location.phone = "555-123-4567"
  location.email = "main@jeffsautomotive.com"
  location.active = true
end

# Set current tenant for seeding
ActsAsTenant.current_tenant = jeffs_shop

# Create users for Jeff's Automotive
puts "Creating or finding users..."
admin_user = User.find_or_create_by!(email: "admin@jeffsautomotive.com") do |user|
  user.password = "password123"
  user.first_name = "Jeff"
  user.last_name = "Thompson"
  user.phone = "555-123-4567"
  user.role = "admin"
  user.location = main_location
end

manager_user = User.find_or_create_by!(email: "manager@jeffsautomotive.com") do |user|
  user.password = "password123"
  user.first_name = "Sarah"
  user.last_name = "Johnson"
  user.phone = "555-123-4568"
  user.role = "manager"
  user.location = main_location
end

technician1 = User.find_or_create_by!(email: "tech1@jeffsautomotive.com") do |user|
  user.password = "password123"
  user.first_name = "Mike"
  user.last_name = "Wilson"
  user.phone = "555-123-4569"
  user.role = "technician"
  user.location = main_location
end

technician2 = User.find_or_create_by!(email: "tech2@jeffsautomotive.com") do |user|
  user.password = "password123"
  user.first_name = "Tom"
  user.last_name = "Davis"
  user.phone = "555-123-4570"
  user.role = "technician"
  user.location = main_location
end

receptionist = User.find_or_create_by!(email: "reception@jeffsautomotive.com") do |user|
  user.password = "password123"
  user.first_name = "Emily"
  user.last_name = "Brown"
  user.phone = "555-123-4571"
  user.role = "receptionist"
  user.location = main_location
end

# Create services
puts "Creating services..."
services = [
  # Default services that are referenced later
  { name: "Oil Change", description: "Full synthetic oil change and filter replacement", price: 49.99, duration_minutes: 30 },
  { name: "Tire Rotation", description: "Rotate tires for even wear", price: 19.99, duration_minutes: 20 },
  { name: "Brake Inspection", description: "Comprehensive brake system inspection", price: 0.00, duration_minutes: 20 },
  # Additional services
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
  main_location.services.find_or_create_by!(name: service_attrs[:name]) do |service|
    service.description = service_attrs[:description]
    service.price = service_attrs[:price]
    service.duration_minutes = service_attrs[:duration_minutes]
  end
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
  customer = Customer.create!(data[:customer].merge(location: main_location))
  data[:vehicles].each do |vehicle_attrs|
    customer.vehicles.create!(vehicle_attrs)
  end
  created_customers << customer
end

# Create past appointments with services
puts "Creating appointment history..."
oil_change = main_location.services.find_by(name: "Oil Change")
tire_rotation = main_location.services.find_by(name: "Tire Rotation")
brake_inspection = main_location.services.find_by(name: "Brake Inspection")
brake_replacement = main_location.services.find_by(name: "Brake Pad Replacement")
air_filter = main_location.services.find_by(name: "Air Filter Replacement")

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
  # Welcome email thread
  thread_id = "email_#{customer.id}_#{SecureRandom.hex(8)}"
  
  welcome_email = customer.communications.create!(
    communication_type: 'email',
    direction: 'outbound',
    subject: 'Welcome to Jeff\'s Automotive!',
    content: "Hi #{customer.first_name},\n\nThank you for choosing Jeff's Automotive for your vehicle service needs. We're committed to providing you with the best automotive care in Rochester.\n\nIf you have any questions, feel free to reply to this email or give us a call.\n\nBest regards,\nThe Jeff's Automotive Team",
    status: 'delivered',
    sent_at: 2.weeks.ago,
    thread_id: thread_id,
    to_email: customer.email,
    user: admin_user
  )
  
  # Customer reply (simulate inbound email)
  if rand < 0.3  # 30% chance of customer reply
    customer.communications.create!(
      communication_type: 'email',
      direction: 'inbound',
      subject: 'Re: Welcome to Jeff\'s Automotive!',
      content: "Thank you for the welcome! I'm looking forward to bringing my #{customer.vehicles.first&.year} #{customer.vehicles.first&.make} #{customer.vehicles.first&.model} in for service.",
      status: 'delivered',
      sent_at: 1.week.ago,
      thread_id: thread_id,
      from_email: customer.email,
      message_id: "msg_#{SecureRandom.hex(16)}"
    )
  end
  
  # SMS reminders
  if customer.phone.present?
    sms_thread_id = "sms_#{customer.id}_#{SecureRandom.hex(8)}"
    
    # Appointment reminder SMS
    customer.communications.create!(
      communication_type: 'sms',
      direction: 'outbound',
      content: "Hi #{customer.first_name}, this is Jeff's Automotive. Your appointment is scheduled for tomorrow at 10 AM. Please reply CONFIRM to confirm or call us at (555) 123-4567.",
      status: 'delivered',
      sent_at: 1.day.ago,
      thread_id: sms_thread_id,
      to_phone: customer.phone,
      user: receptionist
    )
    
    # Customer SMS confirmation (simulate inbound)
    if rand < 0.7  # 70% chance of SMS confirmation
      customer.communications.create!(
        communication_type: 'sms',
        direction: 'inbound',
        content: 'CONFIRM',
        status: 'delivered',
        sent_at: 20.hours.ago,
        thread_id: sms_thread_id,
        from_phone: customer.phone,
        message_id: "sms_#{SecureRandom.hex(16)}"
      )
      
      # Follow-up SMS
      customer.communications.create!(
        communication_type: 'sms',
        direction: 'outbound',
        content: "Perfect! We've confirmed your appointment for tomorrow at 10 AM. See you then!",
        status: 'delivered',
        sent_at: 19.hours.ago,
        thread_id: sms_thread_id,
        to_phone: customer.phone,
        user: receptionist
      )
    end
  end
end

# Create some unread messages
puts "Creating recent unread messages..."
recent_customers = created_customers.last(3)
recent_customers.each do |customer|
  # Unread inquiry email
  thread_id = "email_#{customer.id}_#{SecureRandom.hex(8)}"
  customer.communications.create!(
    communication_type: 'email',
    direction: 'inbound',
    subject: 'Question about service pricing',
    content: "Hi, I was wondering if you could provide a quote for a brake pad replacement on my #{customer.vehicles.first&.year} #{customer.vehicles.first&.make} #{customer.vehicles.first&.model}? Thanks!",
    status: 'delivered',
    created_at: rand(4.hours).seconds.ago,
    thread_id: thread_id,
    from_email: customer.email,
    message_id: "msg_#{SecureRandom.hex(16)}"
  )
  
  # Unread SMS
  if customer.phone.present?
    sms_thread_id = "sms_#{customer.id}_#{SecureRandom.hex(8)}"
    customer.communications.create!(
      communication_type: 'sms',
      direction: 'inbound',
      content: 'Hi, can I reschedule my appointment for next week?',
      status: 'delivered',
      created_at: rand(2.hours).seconds.ago,
      thread_id: sms_thread_id,
      from_phone: customer.phone,
      message_id: "sms_#{SecureRandom.hex(16)}"
    )
  end
end

  puts "\n=== Seeding Complete! ==="
  puts "Shop created: #{jeffs_shop.name} (subdomain: #{jeffs_shop.subdomain})"
  puts "Region created: #{rochester_region.name}"
  puts "Location created: #{main_location.name}"
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
end # ActsAsTenant.without_tenant