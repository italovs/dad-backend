require "test_helper"

class ProductModelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @product_model = product_models(:one)
  end

  test "should get index" do
    get product_models_url, as: :json
    assert_response :success
  end

  test "should create product_model" do
    assert_difference("ProductModel.count") do
      post product_models_url, params: { product_model: { description: @product_model.description, price: @product_model.price, products_id: @product_model.products_id, quantity: @product_model.quantity } }, as: :json
    end

    assert_response :created
  end

  test "should show product_model" do
    get product_model_url(@product_model), as: :json
    assert_response :success
  end

  test "should update product_model" do
    patch product_model_url(@product_model), params: { product_model: { description: @product_model.description, price: @product_model.price, products_id: @product_model.products_id, quantity: @product_model.quantity } }, as: :json
    assert_response :success
  end

  test "should destroy product_model" do
    assert_difference("ProductModel.count", -1) do
      delete product_model_url(@product_model), as: :json
    end

    assert_response :no_content
  end
end
