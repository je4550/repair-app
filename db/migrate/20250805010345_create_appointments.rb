class CreateAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :appointments do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true
      t.datetime :scheduled_at
      t.string :status, default: 'scheduled'
      t.text :notes
      t.monetize :total_price
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :appointments, :deleted_at
    add_index :appointments, :scheduled_at
    add_index :appointments, :status
  end
end
