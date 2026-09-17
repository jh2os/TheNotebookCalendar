module Api
  module Auth
    class SessionsController < ApplicationController
      before_action :require_authentication, only: :destroy

      def show
        if current_user
          render json: { user: { id: current_user.id, email: current_user.email } }, status: :ok
        else
          render json: { error: "Authentication required" }, status: :unauthorized
        end
      end

      def destroy
        reset_session
        head :no_content
      end
    end
  end
end
