class Product < ApplicationRecord
  has_many :product_models, class_name: 'ProductModel', foreign_key: 'products_id', dependent: :destroy

  validates :name, uniqueness: true
end
