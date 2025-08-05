class AddShopToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :shop, null: false, foreign_key: true
  end
end
