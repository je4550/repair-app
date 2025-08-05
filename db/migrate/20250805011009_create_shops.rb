class CreateShops < ActiveRecord::Migration[8.0]
  def change
    create_table :shops do |t|
      t.string :name, null: false
      t.string :subdomain, null: false
      t.string :owner_name
      t.string :phone
      t.string :email
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :state
      t.string :zip
      t.boolean :active, default: true

      t.timestamps
    end
    add_index :shops, :subdomain, unique: true
    add_index :shops, :email
    add_index :shops, :active
  end
end
