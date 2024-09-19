require "test_helper"

class OrderProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @order_product = order_products(:one)
  end

  test "should get index" do
    get order_products_url, as: :json
    assert_response :success
  end

  test "should create order_product" do
    assert_difference("OrderProduct.count") do
      post order_products_url, params: { order_product: { orders_id: @order_product.orders_id, price: @order_product.price, products_id: @order_product.products_id, quantity: @order_product.quantity } }, as: :json
    end

    assert_response :created
  end

  test "should show order_product" do
    get order_product_url(@order_product), as: :json
    assert_response :success
  end

  test "should update order_product" do
    patch order_product_url(@order_product), params: { order_product: { orders_id: @order_product.orders_id, price: @order_product.price, products_id: @order_product.products_id, quantity: @order_product.quantity } }, as: :json
    assert_response :success
  end

  test "should destroy order_product" do
    assert_difference("OrderProduct.count", -1) do
      delete order_product_url(@order_product), as: :json
    end

    assert_response :no_content
  end
end
