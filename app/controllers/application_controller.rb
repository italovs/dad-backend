class ApplicationController < ActionController::API
  def unauthorized_error
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  def unprocessable_entity(msg = "unprocessable entity")
    render json: { error: msg }, status: :unprocessable_entity
  end
end
