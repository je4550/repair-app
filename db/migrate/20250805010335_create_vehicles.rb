class CreateVehicles < ActiveRecord::Migration[8.0]
  def change
    create_table :vehicles do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :vin
      t.string :make
      t.string :model
      t.integer :year
      t.integer :mileage
      t.string :license_plate
      t.string :color
      t.text :notes
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :vehicles, :vin
    add_index :vehicles, :license_plate
    add_index :vehicles, :deleted_at
  end
end
