class AddShopToServices < ActiveRecord::Migration[8.0]
  def change
    add_reference :services, :shop, null: false, foreign_key: true
  end
end
