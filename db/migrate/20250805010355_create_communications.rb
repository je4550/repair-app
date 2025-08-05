class CreateCommunications < ActiveRecord::Migration[8.0]
  def change
    create_table :communications do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :communication_type
      t.string :subject
      t.text :content
      t.datetime :sent_at
      t.string :status

      t.timestamps
    end
  end
end
