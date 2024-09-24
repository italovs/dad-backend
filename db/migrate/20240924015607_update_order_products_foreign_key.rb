class UpdateOrderProductsForeignKey < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :order_products, :products
    remove_column :order_products, :product_id # Remove the product_id column if needed

    # Add the new foreign key referencing product_models
    add_reference :order_products, :product_model, foreign_key: true
  end
end
