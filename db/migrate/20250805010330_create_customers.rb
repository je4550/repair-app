class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :state
      t.string :zip
      t.text :notes
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :customers, :deleted_at
    add_index :customers, :email, unique: true
    add_index :customers, :phone
    add_index :customers, [:last_name, :first_name]
  end
end
