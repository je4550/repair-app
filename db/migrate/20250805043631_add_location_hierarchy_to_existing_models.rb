class AddLocationHierarchyToExistingModels < ActiveRecord::Migration[8.0]
  def up
    # Add location_id to all models that currently have shop_id
    add_reference :customers, :location, null: true, foreign_key: true
    add_reference :users, :location, null: true, foreign_key: true
    add_reference :services, :location, null: true, foreign_key: true
    
    # Indexes are automatically created by the references helper
    
    # Migrate existing data - bypass tenant checks during migration
    ActsAsTenant.without_tenant do
      Shop.find_each do |shop|
        puts "Processing shop: #{shop.name}"
        
        # Create default region for each shop
        region = Region.create!(
          name: "Main Region",
          shop: shop
        )
        puts "Created region: #{region.id}"
        
        # Create default location using shop's address info
        location = Location.create!(
          name: "Main Location",
          address_line1: shop.address_line1,
          address_line2: shop.address_line2,
          city: shop.city,
          state: shop.state,
          zip: shop.zip,
          phone: shop.phone,
          email: shop.email,
          active: shop.active,
          region: region
        )
        puts "Created location: #{location.id}"
        
        # Update all related records to point to the new location using direct SQL
        customers_updated = ActiveRecord::Base.connection.execute(
          "UPDATE customers SET location_id = #{location.id} WHERE shop_id = #{shop.id}"
        )
        users_updated = ActiveRecord::Base.connection.execute(
          "UPDATE users SET location_id = #{location.id} WHERE shop_id = #{shop.id}"
        )
        services_updated = ActiveRecord::Base.connection.execute(
          "UPDATE services SET location_id = #{location.id} WHERE shop_id = #{shop.id}"
        )
        
        puts "Updated #{customers_updated} customers, #{users_updated} users, #{services_updated} services"
      end
    end
    
    # Make location_id required after data migration
    change_column_null :customers, :location_id, false
    change_column_null :users, :location_id, false
    change_column_null :services, :location_id, false
    
    # Remove old shop_id columns
    remove_foreign_key :customers, :shops
    remove_foreign_key :users, :shops
    remove_foreign_key :services, :shops
    
    remove_index :customers, :shop_id
    remove_index :users, :shop_id
    remove_index :services, :shop_id
    
    remove_column :customers, :shop_id
    remove_column :users, :shop_id
    remove_column :services, :shop_id
  end
  
  def down
    # Add shop_id back to all models
    add_reference :customers, :shop, null: true, foreign_key: true
    add_reference :users, :shop, null: true, foreign_key: true
    add_reference :services, :shop, null: true, foreign_key: true
    
    # Migrate data back
    Location.find_each do |location|
      shop = location.region.shop
      location.customers.update_all(shop_id: shop.id)
      location.users.update_all(shop_id: shop.id) 
      location.services.update_all(shop_id: shop.id)
    end
    
    # Make shop_id required
    change_column_null :customers, :shop_id, false
    change_column_null :users, :shop_id, false
    change_column_null :services, :shop_id, false
    
    # Remove location references
    remove_foreign_key :customers, :locations
    remove_foreign_key :users, :locations
    remove_foreign_key :services, :locations
    
    remove_column :customers, :location_id
    remove_column :users, :location_id
    remove_column :services, :location_id
  end
end
