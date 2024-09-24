class ProductsController < ApplicationController
  before_action :set_product, only: %i[update show]
  before_action :authenticate_user!, only: %i[create update delete aws_upload_link]

  # GET /products
  def index
    @products = ProductModel
                .select('product_models.*, MIN(price) AS min_price')
                .where('quantity > ?', 0)
                .group(:products_id, :id)
                .having('price = MIN(price)')

    if params[:search].present?
      search_term = "%#{params[:search]}%"

      @products = @products.joins('LEFT JOIN products on products.id = product_models.products_id')
                           .where(
                             'products.name ILIKE ? OR product_models.description ILIKE ?',
                             search_term,
                             search_term
                           )
    end

    if params[:category].present?
      @products = @products.joins('LEFT JOIN products on products.id = product_models.products_id')
                           .where(products: { category: params[:category] })
    end

    products_hash = @products.map do |product|
      parse_product_to_hash(product)
    end

    render json: products_hash
  end

  # GET /products/home
  def home
    expensive_products = ProductModel
                         .select('product_models.*, MIN(product_models.price) AS min_price')
                         .joins('JOIN products on products.id = product_models.products_id')
                         .where('product_models.quantity > ?', 0)
                         .group(:products_id, :id)
                         .order('min_price DESC')
                         .limit(3)

    excluded_categories = expensive_products.map { |product_model| product_model.product.category }

    category_products = ProductModel
                        .select('product_models.*, MIN(product_models.price) AS min_price')
                        .joins('JOIN products on products.id = product_models.products_id')
                        .where('product_models.quantity > ?', 0)
                        .where.not(products: { category: excluded_categories })
                        .group(:products_id, :id)
                        .group_by { |model| model.product.category }
                        .map { |_, models| models.first }

    expensive_products_hash = expensive_products.map { |product_model| parse_product_to_hash(product_model) }

    category_products_hash = category_products.map { |product_model| parse_product_to_hash(product_model) }

    render json: {
      expensive_products: expensive_products_hash,
      category_products: category_products_hash
    }
  end

  # GET /products/1
  def show
    product_hash = {
      product: {
        id: @product.id,
        name: @product.name,
        category: @product.category,
        created_at: @product.created_at,
        updated_at: @product.updated_at
      },
      product_models: @product.product_models.map { |model| parse_product_model_to_hash(model) }
    }

    render json: product_hash
  end

  # POST /products
  def create
    return unauthorized_error unless current_user.admin?

    product_params = params[:product]
    product_models_params = product_params[:product_models]

    return unprocessable_entity('Product must have at least one model') if product_models_params.blank?

    ActiveRecord::Base.transaction do
      @product = Product.create!(
        name: product_params[:name],
        category: product_params[:category]
      )

      product_models_params.each do |product_model_params|
        product_model = ProductModel.create!(
          description: product_model_params[:description],
          price: product_model_params[:price],
          quantity: product_model_params[:quantity],
          products_id: @product.id
        )

        bucket = ENV['AWS_BUCKET']

        s3_client = create_aws_client
        resource = Aws::S3::Resource.new(client: s3_client)
        obj = resource.bucket(bucket).object(product_model_params[:image_key])

        blob = ActiveStorage::Blob.create_before_direct_upload!(
          filename: File.basename(product_model_params[:image_key]),
          byte_size: obj.size,
          checksum: obj.etag.gsub('"', ""),
          key: product_model_params[:image_key],
          content_type: obj.content_type
        )

        product_model.image.attach(blob)
      end

      render json: { product: @product, product_models: @product.product_models }, status: :created, location: @product
    end
  rescue StandardError => e
    render json: e.message, status: :unprocessable_entity
  end

  def categories
    products_categories = Product.all.pluck(:category).uniq

    render json: { categories: products_categories }, status: :ok
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

  def aws_upload_link
    return unauthorized_error unless current_user.admin?

    bucket = ENV['AWS_BUCKET']

    filename = params[:filename]
    object_key = "#{SecureRandom.uuid}_#{filename}"

    # s3_client = Aws::S3::Client.new(region: aws_region)
    s3_client = create_aws_client

    signer = Aws::S3::Presigner.new(client: s3_client)

    presigned_url = signer.presigned_url(
      :put_object,
      bucket: bucket,
      key: object_key,
      expires_in: 600
    )

    render json: { url: presigned_url, key: object_key }
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_product
    @product = Product.includes(:product_models).find(params[:id])
  end

  def parse_product_to_hash(product_model)
    {
      id: product_model.product.id,
      name: product_model.product.name,
      category: product_model.product.category,

      product_model_id: product_model.id,
      description: product_model.description,
      price: product_model.price,
      quantity: product_model.quantity,
      created_at: product_model.created_at,
      updated_at: product_model.updated_at
      # url: product_model.url # TODO: Adicionar URL quando for implementado
    }
  end

  def parse_product_model_to_hash(product_model)
    {
      id: product_model.id,
      description: product_model.description,
      price: product_model.price,
      quantity: product_model.quantity,
      url: url_for(product_model.image), # TODO: Adicionar URL quando for implementado
      created_at: product_model.created_at,
      updated_at: product_model.updated_at
    }
  end

  # Only allow a list of trusted parameters through.
  def product_params
    params.require(:product).permit(
      :name, :category,
      product_models: %i[description price quantity] # TODO: Adicionar URL quando for implementado
    )
  end

  def create_aws_client
    aws_region = ENV['AWS_REGION']
    access_key = ENV['AWS_ACCESS_KEY']
    secret_key = ENV['AWS_SECRET_KEY']

    Aws::S3::Client.new(region: aws_region, credentials: Aws::Credentials.new(access_key, secret_key))
  end
end
