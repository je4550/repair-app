class CreateLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.string :name, null: false
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :state
      t.string :zip
      t.string :phone
      t.string :email
      t.boolean :active, default: true
      t.references :region, null: false, foreign_key: true
      t.datetime :deleted_at

      t.timestamps
    end
    
    add_index :locations, :deleted_at
    add_index :locations, :active
    add_index :locations, [:city, :state]
  end
end
