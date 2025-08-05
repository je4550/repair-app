class CreateServiceReminders < ActiveRecord::Migration[8.0]
  def change
    create_table :service_reminders do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true
      t.string :reminder_type
      t.date :scheduled_date
      t.string :status
      t.datetime :sent_at

      t.timestamps
    end
  end
end
