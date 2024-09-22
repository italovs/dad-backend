class RenameOrderAndProductIdsInOrderProducts < ActiveRecord::Migration[7.0]
  def change
    rename_column :order_products, :orders_id, :order_id
    rename_column :order_products, :products_id, :product_id
  end
end
