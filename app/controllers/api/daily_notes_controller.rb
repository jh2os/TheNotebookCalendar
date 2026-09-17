module Api
  class DailyNotesController < ApplicationController
    before_action :require_authentication
    before_action :set_calendar

    def index
      start_date = parse_date(params[:start_date])
      end_date = parse_date(params[:end_date])
      return render_date_error unless start_date && end_date && start_date <= end_date

      notes = @calendar.daily_notes.where(date: start_date..end_date).order(:date)
      render json: { notes: notes.map { |note| note_json(note) } }
    end

    def show
      note = @calendar.daily_notes.find_by(date: parse_date!(params[:date]))
      return render json: { error: "Note not found" }, status: :not_found unless note

      render json: { note: note_json(note) }
    end

    def upsert
      date = parse_date!(params[:date])
      body = params.require(:note).permit(:body).fetch(:body, "").to_s

      if body.strip.empty?
        @calendar.daily_notes.find_by(date: date)&.destroy!
        return head :no_content
      end

      note = @calendar.daily_notes.find_or_initialize_by(date: date)
      note.body = body

      if note.save
        render json: { note: note_json(note) }, status: :ok
      else
        render json: { errors: note.errors.to_hash }, status: :unprocessable_entity
      end
    end

    def destroy
      note = @calendar.daily_notes.find_by(date: parse_date!(params[:date]))
      return render json: { error: "Note not found" }, status: :not_found unless note

      note.destroy!
      head :no_content
    end

    private

    def set_calendar
      @calendar = current_user.calendars.find(params[:calendar_id])
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end

    def parse_date!(value)
      parse_date(value) || raise(ActionController::BadRequest, "Date must use YYYY-MM-DD format")
    end

    def render_date_error
      render json: { error: "start_date and end_date must be valid YYYY-MM-DD dates with start_date before end_date" }, status: :bad_request
    end

    def note_json(note)
      {
        id: note.id,
        calendar_id: note.calendar_id,
        date: note.date.iso8601,
        body: note.body,
        created_at: note.created_at,
        updated_at: note.updated_at
      }
    end
  end
end
