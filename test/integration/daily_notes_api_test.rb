require "test_helper"

class DailyNotesApiTest < ActionDispatch::IntegrationTest
  setup do
    @member = User.create!(email: "member@example.com")
    @outsider = User.create!(email: "outsider@example.com")
    @calendar = Calendar.create!(name: "Notes calendar", creator: @member)
    @calendar.calendar_memberships.create!(user: @member, role: "owner")
    authenticate_as(@member)
  end

  test "retrieves notes within an inclusive date range" do
    create_note("2026-09-01", "First")
    create_note("2026-09-16", "Middle")
    create_note("2026-09-30", "Last")
    create_note("2026-10-01", "Outside")

    get api_calendar_notes_url(calendar_id: @calendar.id, start_date: "2026-09-01", end_date: "2026-09-30"), as: :json

    assert_response :success
    assert_equal %w[2026-09-01 2026-09-16 2026-09-30], response.parsed_body.fetch("notes").map { |note| note["date"] }
  end

  test "rejects invalid or reversed date ranges" do
    get api_calendar_notes_url(calendar_id: @calendar.id, start_date: "2026-09-20", end_date: "2026-09-01"), as: :json
    assert_response :bad_request

    get api_calendar_notes_url(calendar_id: @calendar.id, start_date: "not-a-date", end_date: "2026-09-30"), as: :json
    assert_response :bad_request
  end

  test "creates and updates a note for one day" do
    put api_calendar_note_url(calendar_id: @calendar.id, date: "2026-09-16"), params: { note: { body: "Initial" } }, as: :json
    assert_response :success
    assert_equal "Initial", response.parsed_body.dig("note", "body")

    put api_calendar_note_url(calendar_id: @calendar.id, date: "2026-09-16"), params: { note: { body: "Updated" } }, as: :json
    assert_response :success
    assert_equal "Updated", response.parsed_body.dig("note", "body")
    assert_equal 1, @calendar.daily_notes.count
  end

  test "reads, clears, and deletes a note" do
    create_note("2026-09-16", "Remember this")

    get api_calendar_note_url(calendar_id: @calendar.id, date: "2026-09-16"), as: :json
    assert_response :success
    assert_equal "Remember this", response.parsed_body.dig("note", "body")

    put api_calendar_note_url(calendar_id: @calendar.id, date: "2026-09-16"), params: { note: { body: "   " } }, as: :json
    assert_response :no_content
    assert_not @calendar.daily_notes.exists?(date: "2026-09-16")

    create_note("2026-09-16", "Delete this")
    delete api_calendar_note_url(calendar_id: @calendar.id, date: "2026-09-16"), as: :json
    assert_response :no_content
  end

  test "rejects missing and malformed single-day notes" do
    get api_calendar_note_url(calendar_id: @calendar.id, date: "2026-09-16"), as: :json
    assert_response :not_found

    get api_calendar_note_url(calendar_id: @calendar.id, date: "09-16-2026"), as: :bad_request
    assert_response :bad_request
  end

  test "non-members cannot read or modify notes" do
    @calendar.daily_notes.create!(date: Date.new(2026, 9, 16), body: "Private")
    authenticate_as(@outsider)

    get api_calendar_notes_url(calendar_id: @calendar.id, start_date: "2026-09-01", end_date: "2026-09-30"), as: :json
    assert_response :not_found

    put api_calendar_note_url(calendar_id: @calendar.id, date: "2026-09-16"), params: { note: { body: "Changed" } }, as: :json
    assert_response :not_found

    delete api_calendar_note_url(calendar_id: @calendar.id, date: "2026-09-16"), as: :json
    assert_response :not_found
  end

  private

  def authenticate_as(user)
    token = user.issue_magic_link!
    get api_auth_magic_link_url(token: token), as: :json
    assert_response :success
  end

  def create_note(date, body)
    @calendar.daily_notes.create!(date: Date.iso8601(date), body: body)
  end
end
