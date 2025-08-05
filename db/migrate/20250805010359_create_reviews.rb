class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :appointment, null: false, foreign_key: true
      t.integer :rating
      t.text :comment
      t.string :source
      t.datetime :review_date

      t.timestamps
    end
  end
end
