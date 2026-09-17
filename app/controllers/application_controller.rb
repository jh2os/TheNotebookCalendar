class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found

  helper_method :current_user

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def render_record_not_found
    render json: { error: "Resource not found" }, status: :not_found
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def require_authentication
    return if current_user

    render json: { error: "Authentication required" }, status: :unauthorized
  end
end
