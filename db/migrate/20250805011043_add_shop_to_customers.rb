class AddShopToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_reference :customers, :shop, null: false, foreign_key: true
  end
end
