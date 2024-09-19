class CreateOrderProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :order_products do |t|
      t.references :orders, null: false, foreign_key: true
      t.references :products, null: false, foreign_key: true
      t.float :price
      t.integer :quantity

      t.timestamps
    end
  end
end
