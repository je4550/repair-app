class UpdateServiceNameUniqueConstraint < ActiveRecord::Migration[8.0]
  def change
    # Remove the existing unique index on name
    remove_index :services, :name
    
    # Add a new unique index scoped by shop_id
    add_index :services, [:shop_id, :name], unique: true
  end
end
