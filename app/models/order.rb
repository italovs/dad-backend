class Order < ApplicationRecord
  belongs_to :users, class_name: "User"

  has_many :order_products

  alias user users

  enum status: { pending: 0, finished: 1 }

  def total_price
    total_price = 0.0

    order_products.each do |order_product|
      total_price += (order_product.price * order_product.quantity)
    end

    total_price
  end
end
