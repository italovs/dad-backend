class OrderProduct < ApplicationRecord
  belongs_to :order, class_name: "Order"
  belongs_to :product_model, class_name: "ProductModel"
end
