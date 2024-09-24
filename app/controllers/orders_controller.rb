class OrdersController < ApplicationController
  before_action :set_order, only: %i[show update destroy]
  before_action :authenticate_user!

  # GET /orders
  def index
    @orders = if current_user.admin?
                Order.all
              else
                Order.where(users_id: current_user.id)
              end

    @orders = [] if @orders.nil?

    orders_json = @orders.map do |order|
      {
        id: order.id,
        total_price: order.total_price,
        created_at: order.created_at,
        updated_at: order.updated_at,
        user_id: order.users_id
      }
    end

    render json: orders_json
  end

  # GET /orders/1
  def show
    return unauthorized_error if @order.users_id != current_user.id && !current_user.admin?

    order_products_json = @order.order_products.map do |order_product|
      {
        id: order_product.product_model_id,
        name: order_product.product_model.product.name,
        category: order_product.product_model.product.category,
        description: order_product.product_model.description,
        price: order_product.price,
        quantity: order_product.quantity
      }
    end

    order_json = {
      id: @order.id,
      user_id: @order.users_id,
      product_models: order_products_json,
      total_price: @order.total_price,
      created_at: @order.created_at,
      updated_at: @order.updated_at
    }
    render json: order_json
  end

  # POST /orders
  def create
    total_price = 0
    product_models = params[:order]['product_models'].map do |product_params|
      product_model = ProductModel.find_by!(
        'quantity >= ? and id = ?',
        product_params[:quantity],
        product_params[:id]
      )

      [
        product_model,
        product_params[:quantity]
      ]
    end

    puts product_models

    raise ActiveRecord::RecordNotFound if product_models.blank?

    product_models.each do |product_model|
      unit_price = product_model[0].price
      product_quantity = product_model[1]

      total_price += (unit_price * product_quantity)
    end

    ActiveRecord::Base.transaction do
      @order = Order.create(users_id: params[:order][:user_id], status: Order.statuses[:pending])

      product_models.each do |product_model|
        product = product_model[0]
        quantity = product_model [1]

        OrderProduct.create!(
          order_id: @order.id,
          product_model_id: product.id,
          price: product.price,
          quantity: quantity
        )

        product.quantity -= quantity
        product.save
      end
    end

    if @order.save
      render json: @order, status: :created, location: @order
    else
      render json: @order.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /orders/1
  def update
    if @order.update(order_params)
      render json: @order
    else
      render json: @order.errors, status: :unprocessable_entity
    end
  end

  # DELETE /orders/1
  def destroy
    @order.destroy
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_order
    @order = Order.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def order_params
    params.require(:order).permit(:users_id, product_model_params: [])
  end
end
