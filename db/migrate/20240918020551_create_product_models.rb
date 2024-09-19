class CreateProductModels < ActiveRecord::Migration[7.0]
  def change
    create_table :product_models do |t|
      t.string :description
      t.float :price
      t.integer :quantity
      t.references :products, null: false, foreign_key: true

      t.timestamps
    end
  end
end
