module Api
  class CalendarMembershipsController < ApplicationController
    before_action :require_authentication
    before_action :set_calendar
    before_action :require_owner

    def index
      render json: { members: @calendar.calendar_memberships.includes(:user).map { |membership| membership_json(membership) } }
    end

    def create
      user = User.find_by(email: normalized_email)
      return render json: { error: "User not found" }, status: :not_found unless user

      membership = @calendar.calendar_memberships.create(user: user, role: "member")
      if membership.persisted?
        render json: { member: membership_json(membership) }, status: :created
      else
        render json: { errors: membership.errors.to_hash }, status: :unprocessable_entity
      end
    end

    def destroy
      membership = @calendar.calendar_memberships.find_by(user_id: params[:user_id])
      return render json: { error: "Member not found" }, status: :not_found unless membership
      return render json: { error: "The owner cannot be removed" }, status: :forbidden if membership.role == "owner"

      membership.destroy!
      head :no_content
    end

    private

    def set_calendar
      @calendar = current_user.calendars.find(params[:calendar_id])
    end

    def require_owner
      return if @calendar.calendar_memberships.exists?(user: current_user, role: "owner")

      render json: { error: "Calendar owner access required" }, status: :forbidden
    end

    def normalized_email
      params.require(:email).to_s.strip.downcase
    end

    def membership_json(membership)
      {
        user_id: membership.user_id,
        email: membership.user.email,
        role: membership.role,
        created_at: membership.created_at
      }
    end
  end
end
