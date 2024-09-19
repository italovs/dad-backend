class ProductModel < ApplicationRecord
  belongs_to :products, class_name: "Product"

  alias product products

  has_one_attached :image
end
