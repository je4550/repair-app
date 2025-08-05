class CreateServices < ActiveRecord::Migration[8.0]
  def change
    create_table :services do |t|
      t.string :name
      t.text :description
      t.monetize :price
      t.integer :duration_minutes
      t.boolean :active, default: true
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :services, :deleted_at
    add_index :services, :name, unique: true
    add_index :services, :active
  end
end
