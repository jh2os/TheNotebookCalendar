module Api
  class CalendarsController < ApplicationController
    before_action :require_authentication
    before_action :set_calendar, only: %i[show update destroy]
    before_action :require_owner, only: %i[update destroy]

    def index
      render json: { calendars: current_user.calendars.map { |calendar| calendar_json(calendar) } }
    end

    def show
      render json: { calendar: calendar_json(@calendar) }
    end

    def create
      calendar = Calendar.transaction do
        new_calendar = current_user.owned_calendars.create!(calendar_params)
        new_calendar.calendar_memberships.create!(user: current_user, role: "owner")
        new_calendar
      end

      render json: { calendar: calendar_json(calendar) }, status: :created
    rescue ActiveRecord::RecordInvalid => error
      render json: { errors: error.record.errors.to_hash }, status: :unprocessable_entity
    end

    def update
      if @calendar.update(calendar_params)
        render json: { calendar: calendar_json(@calendar) }
      else
        render json: { errors: @calendar.errors.to_hash }, status: :unprocessable_entity
      end
    end

    def destroy
      @calendar.destroy!
      head :no_content
    end

    private

    def set_calendar
      @calendar = current_user.calendars.find(params[:id])
    end

    def require_owner
      return if @calendar.calendar_memberships.exists?(user: current_user, role: "owner")

      render json: { error: "Calendar owner access required" }, status: :forbidden
    end

    def calendar_params
      params.require(:calendar).permit(:name)
    end

    def calendar_json(calendar)
      {
        id: calendar.id,
        name: calendar.name,
        created_by_id: calendar.created_by_id,
        created_at: calendar.created_at,
        updated_at: calendar.updated_at
      }
    end
  end
end
