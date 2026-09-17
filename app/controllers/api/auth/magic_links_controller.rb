module Api
  module Auth
    class MagicLinksController < ApplicationController
      def create
        user = User.find_by(email: normalized_email)
        deliver_magic_link(user) if user

        render json: { message: "If an account exists, a magic link has been sent." }, status: :accepted
      end

      def show
        user = User.find_by(magic_link_digest: User.digest_magic_link(params[:token]))

        unless user&.authenticate_magic_link!(params[:token])
          return render json: { error: "Invalid or expired magic link" }, status: :unauthorized
        end

        reset_session
        session[:user_id] = user.id
        render json: { user: { id: user.id, email: user.email } }, status: :ok
      end

      private

      def normalized_email
        params.require(:email).to_s.strip.downcase
      end

      def deliver_magic_link(user)
        token = user.issue_magic_link!
          MagicLinkMailer.login(user, token).deliver_now
      end
    end
  end
end
