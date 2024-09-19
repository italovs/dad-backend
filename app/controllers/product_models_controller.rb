class ProductModelsController < ApplicationController
  before_action :set_product_model, only: %i[ show update destroy ]

  # GET /product_models
  def index
    @product_models = ProductModel.all

    render json: @product_models
  end

  # GET /product_models/1
  def show
    render json: @product_model
  end

  # POST /product_models
  def create
    @product_model = ProductModel.new(product_model_params)

    if @product_model.save
      render json: @product_model, status: :created, location: @product_model
    else
      render json: @product_model.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /product_models/1
  def update
    if @product_model.update(product_model_params)
      render json: @product_model
    else
      render json: @product_model.errors, status: :unprocessable_entity
    end
  end

  # DELETE /product_models/1
  def destroy
    @product_model.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product_model
      @product_model = ProductModel.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def product_model_params
      params.require(:product_model).permit(:description, :price, :quantity, :products_id)
    end
end
