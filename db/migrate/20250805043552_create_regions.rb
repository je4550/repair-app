class CreateRegions < ActiveRecord::Migration[8.0]
  def change
    create_table :regions do |t|
      t.string :name, null: false
      t.references :shop, null: false, foreign_key: true
      t.datetime :deleted_at

      t.timestamps
    end
    
    add_index :regions, :deleted_at
  end
end
