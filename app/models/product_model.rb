class ProductModel < ApplicationRecord
  belongs_to :products, class_name: "Product"

  alias product products

  has_one_attached :image

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
end
