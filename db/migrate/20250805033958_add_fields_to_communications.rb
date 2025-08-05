class AddFieldsToCommunications < ActiveRecord::Migration[8.0]
  def change
    add_column :communications, :direction, :string, default: 'outbound', null: false
    # Skip subject column as it already exists
    add_column :communications, :from_phone, :string
    add_column :communications, :to_phone, :string
    add_column :communications, :from_email, :string
    add_column :communications, :to_email, :string
    add_column :communications, :read_at, :datetime
    add_column :communications, :message_id, :string
    add_column :communications, :thread_id, :string
    add_reference :communications, :user, foreign_key: true

    add_index :communications, :direction
    add_index :communications, :thread_id
    add_index :communications, :message_id
    add_index :communications, [ :customer_id, :communication_type, :direction ], name: 'idx_comms_on_cust_type_dir'
  end
end
