ActsAsTenant.without_tenant do
  shop = Shop.find_by(subdomain: 'jeffs')
  ActsAsTenant.current_tenant = shop
  
  # Create Houston region
  houston = Region.create!(
    name: 'Houston Region',
    shop: shop
  )
  
  # Create Dallas region  
  dallas = Region.create!(
    name: 'Dallas Region',
    shop: shop
  )
  
  # Create Houston locations
  Location.create!(
    name: 'Houston Northwest',
    address_line1: '1234 Northwest Freeway',
    city: 'Houston',
    state: 'TX',
    zip: '77040',
    phone: '713-555-0001',
    email: 'houston.nw@jeffsauto.com',
    region: houston,
    active: true
  )
  
  Location.create!(
    name: 'Houston Downtown',
    address_line1: '567 Main Street',
    city: 'Houston', 
    state: 'TX',
    zip: '77002',
    phone: '713-555-0002',
    email: 'houston.dt@jeffsauto.com',
    region: houston,
    active: true
  )
  
  Location.create!(
    name: 'Houston Galleria',
    address_line1: '890 Westheimer Road',
    city: 'Houston',
    state: 'TX',
    zip: '77056',
    phone: '713-555-0003',
    email: 'houston.galleria@jeffsauto.com',
    region: houston,
    active: true
  )
  
  # Create Dallas locations
  Location.create!(
    name: 'Dallas North',
    address_line1: '1111 Preston Road',
    city: 'Dallas',
    state: 'TX',
    zip: '75230',
    phone: '214-555-0001',
    email: 'dallas.north@jeffsauto.com',
    region: dallas,
    active: true
  )
  
  Location.create!(
    name: 'Dallas Downtown',
    address_line1: '222 Commerce Street',
    city: 'Dallas',
    state: 'TX',
    zip: '75201',
    phone: '214-555-0002',
    email: 'dallas.dt@jeffsauto.com',
    region: dallas,
    active: true
  )
  
  puts 'Created regions and locations successfully!'
  
  # Show what we created
  puts "\nRegions:"
  Region.all.each { |r| puts "  #{r.name} - #{r.locations.count} locations" }
  
  puts "\nLocations:"
  Location.all.order(:region_id, :name).each do |l| 
    puts "  #{l.name} (#{l.region.name}) - #{l.city}, #{l.state}"
  end
end