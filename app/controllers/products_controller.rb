class ProductsController < ApplicationController
  before_action :set_product, only: %i[update]
  before_action :authenticate_user!, only: %i[create update delete]

  # GET /products
  def index
    @products = ProductModel
                .select('product_models.*, MIN(price) AS min_price')
                .where('quantity > ?', 0)
                .group(:products_id, :id)
                .having('price = MIN(price)')

    products_hash = @products.map do |product|
      parse_product_to_hash(product)
    end

    render json: products_hash
  end

  # GET /products/1
  def show
    model = ProductModel.find(params[:id])

    product = parse_product_to_hash(model)

    render json: product
  end

  # POST /products
  def create
    return unauthorized_error unless current_user.admin?

    product_params = params[:product]
    product_models_params = [product_params.fetch(:product_models, {}).values].flatten

    return unprocessable_entity('Product must have at least one Model') if product_models_params.blank?

    ActiveRecord::Base.transaction do
      @product = Product.create!(
        name: product_params[:name],
        category: product_params[:category]
      )

      product_models_params.each do |product_model_params|
        product_model_params[:products_id] = @product.id

        ProductModel.create!(
          description: product_model_params[:description],
          price: product_model_params[:price],
          quantity: product_model_params[:quantity],
          products_id: @product.id,
          image: product_model_params[:image]
        )
      end
      render json: @product, status: :created, location: @product
    end
  rescue StandardError => e
    render json: e.message, status: :unprocessable_entity
  end

  # PATCH/PUT /products/1
  def update
    return unauthorized_error unless current_user.admin?

    if @product.update(product_params)
      render json: @product
    else
      render json: @product.errors, status: :unprocessable_entity
    end
  end

  # DELETE /products/1
  def destroy
    return unauthorized_error unless current_user.admin?

    product_model = ProductModel.find(params[:id])
    product = product_model.product
    ActiveRecord::Base.transaction do
      product_model.destroy
      product.destroy unless product.product_models.any?
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_product
    @product = Product.find(params[:id])
  end

  def parse_product_to_hash(product_model)
    url = if product_model.image.attached?
            rails_blob_url(product_model.image, only_path: true)
          else
            ''
          end

    {
      id: product_model.id,
      name: product_model.product.name,
      category: product_model.product.category,
      description: product_model.description,
      price: product_model.price,
      quantity: product_model.quantity,
      created_at: product_model.created_at,
      updated_at: product_model.updated_at,
      url: url
    }
  end

  # Only allow a list of trusted parameters through.
  def product_params
    params.require(:product).permit(:name, :category, product_models: %i[description price quantity image])
  end
end
