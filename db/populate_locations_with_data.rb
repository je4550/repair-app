ActsAsTenant.without_tenant do
  shop = Shop.find_by(subdomain: 'jeffs')
  ActsAsTenant.current_tenant = shop
  
  # Get locations
  houston_nw = Location.find_by(name: 'Houston Northwest')
  houston_dt = Location.find_by(name: 'Houston Downtown')
  dallas_north = Location.find_by(name: 'Dallas North')
  
  # Create users for different locations
  User.create!(
    email: 'manager.houston@jeffsauto.com',
    password: 'password123',
    first_name: 'Sarah',
    last_name: 'Johnson',
    role: 'manager',
    phone: '713-555-1000',
    location: houston_nw,
    active: true
  )
  
  User.create!(
    email: 'tech.dallas@jeffsauto.com',
    password: 'password123',
    first_name: 'Mike',
    last_name: 'Williams',
    role: 'technician',
    phone: '214-555-2000',
    location: dallas_north,
    active: true
  )
  
  # Create customers for Houston Northwest
  5.times do |i|
    customer = Customer.create!(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      email: Faker::Internet.email,
      phone: "713-555-#{3000 + i}",
      address_line1: Faker::Address.street_address,
      city: 'Houston',
      state: 'TX',
      zip: '77040',
      location: houston_nw
    )
    
    # Add a vehicle
    Vehicle.create!(
      customer: customer,
      make: ['Toyota', 'Honda', 'Ford', 'Chevrolet'].sample,
      model: ['Camry', 'Accord', 'F-150', 'Silverado'].sample,
      year: rand(2015..2023),
      vin: Faker::Vehicle.vin,
      license_plate: "TX#{rand(100..999)}#{('A'..'Z').to_a.sample(3).join}",
      color: ['White', 'Black', 'Silver', 'Blue'].sample,
      mileage: rand(10000..80000)
    )
  end
  
  # Create customers for Houston Downtown
  3.times do |i|
    customer = Customer.create!(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      email: Faker::Internet.email,
      phone: "713-555-#{4000 + i}",
      address_line1: Faker::Address.street_address,
      city: 'Houston',
      state: 'TX',
      zip: '77002',
      location: houston_dt
    )
    
    Vehicle.create!(
      customer: customer,
      make: ['Tesla', 'BMW', 'Mercedes'].sample,
      model: ['Model 3', '3 Series', 'C-Class'].sample,
      year: rand(2020..2023),
      vin: Faker::Vehicle.vin,
      license_plate: "TX#{rand(100..999)}#{('A'..'Z').to_a.sample(3).join}",
      color: ['White', 'Black', 'Gray'].sample,
      mileage: rand(5000..30000)
    )
  end
  
  # Create customers for Dallas North
  4.times do |i|
    customer = Customer.create!(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      email: Faker::Internet.email,
      phone: "214-555-#{5000 + i}",
      address_line1: Faker::Address.street_address,
      city: 'Dallas',
      state: 'TX',
      zip: '75230',
      location: dallas_north
    )
    
    Vehicle.create!(
      customer: customer,
      make: ['Lexus', 'Audi', 'Mazda'].sample,
      model: ['RX350', 'Q5', 'CX-5'].sample,
      year: rand(2018..2023),
      vin: Faker::Vehicle.vin,
      license_plate: "TX#{rand(100..999)}#{('A'..'Z').to_a.sample(3).join}",
      color: ['Pearl White', 'Metallic Blue', 'Red'].sample,
      mileage: rand(15000..60000)
    )
  end
  
  puts "Data created successfully!"
  puts "\nCustomers by location:"
  Location.all.order(:region_id, :name).each do |location|
    count = Customer.where(location: location).count
    puts "  #{location.name}: #{count} customers"
  end
  
  puts "\nUsers by location:"
  Location.all.order(:region_id, :name).each do |location|
    users = User.where(location: location)
    if users.any?
      puts "  #{location.name}:"
      users.each { |u| puts "    - #{u.full_name} (#{u.role}) - #{u.email}" }
    end
  end
end