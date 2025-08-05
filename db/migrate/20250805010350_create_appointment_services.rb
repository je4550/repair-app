class CreateAppointmentServices < ActiveRecord::Migration[8.0]
  def change
    create_table :appointment_services do |t|
      t.references :appointment, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true
      t.integer :quantity, default: 1
      t.monetize :price

      t.timestamps
    end
    add_index :appointment_services, [:appointment_id, :service_id], unique: true, name: 'index_appointment_services_on_appointment_and_service'
  end
end
