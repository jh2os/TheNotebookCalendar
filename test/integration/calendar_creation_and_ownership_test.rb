require "test_helper"

class CalendarCreationAndOwnershipTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "owner@example.com")
    @other_user = User.create!(email: "other@example.com")
    authenticate_as(@user)
  end

  test "creates multiple calendars with owner memberships" do
    post api_calendars_url, params: { calendar: { name: "Personal" } }, as: :json
    first_calendar = response.parsed_body.fetch("calendar")

    post api_calendars_url, params: { calendar: { name: "Work" } }, as: :json
    second_calendar = response.parsed_body.fetch("calendar")

    assert_response :created
    assert_not_equal first_calendar["id"], second_calendar["id"]
    assert_equal 2, @user.reload.owned_calendars.count
    assert_equal 2, @user.calendars.count
    assert_equal %w[owner owner], @user.calendar_memberships.pluck(:role).sort
  end

  test "lists only calendars the current user belongs to" do
    owned_calendar = Calendar.create!(name: "Owned", creator: @user)
    owned_calendar.calendar_memberships.create!(user: @user, role: "owner")
    other_calendar = Calendar.create!(name: "Private", creator: @other_user)
    other_calendar.calendar_memberships.create!(user: @other_user, role: "owner")

    get api_calendars_url, as: :json

    assert_response :success
    assert_equal [ owned_calendar.id ], response.parsed_body.fetch("calendars").map { |calendar| calendar["id"] }
  end

  test "reads and renames an accessible calendar" do
    calendar = create_calendar("Original")

    get api_calendar_url(calendar), as: :json
    assert_response :success
    assert_equal "Original", response.parsed_body.dig("calendar", "name")

    patch api_calendar_url(calendar), params: { calendar: { name: "Renamed" } }, as: :json
    assert_response :success
    assert_equal "Renamed", response.parsed_body.dig("calendar", "name")
  end

  test "rejects access to another user's calendar" do
    calendar = Calendar.create!(name: "Private", creator: @other_user)
    calendar.calendar_memberships.create!(user: @other_user, role: "owner")

    get api_calendar_url(calendar), as: :json

    assert_response :not_found
  end

  test "deletes the calendar and dependent records" do
    calendar = create_calendar("Temporary")
    DailyNote.create!(calendar: calendar, date: Date.new(2026, 9, 16), body: "Remove me")

    delete api_calendar_url(calendar), as: :json

    assert_response :no_content
    assert_not Calendar.exists?(calendar.id)
    assert_not CalendarMembership.exists?(calendar_id: calendar.id)
    assert_not DailyNote.exists?(calendar_id: calendar.id)
  end

  test "requires authentication" do
    reset!
    get api_calendars_url, as: :json

    assert_response :unauthorized
  end

  private

  def authenticate_as(user)
    token = user.issue_magic_link!
    get api_auth_magic_link_url(token: token), as: :json
    assert_response :success
  end

  def create_calendar(name)
    calendar = Calendar.create!(name: name, creator: @user)
    calendar.calendar_memberships.create!(user: @user, role: "owner")
    calendar
  end
end
