require "test_helper"

class AuthorizationSecurityHardeningTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email: "owner@example.com")
    @member = User.create!(email: "member@example.com")
    @outsider = User.create!(email: "outsider@example.com")
    @calendar = create_calendar("Shared", @owner)
    @other_calendar = create_calendar("Private", @outsider)
    @calendar.calendar_memberships.create!(user: @member, role: "member")
  end

  test "all protected resources reject unauthenticated requests" do
    get api_calendars_url, as: :json
    assert_response :unauthorized

    get api_calendar_url(@calendar), as: :json
    assert_response :unauthorized

    get api_calendar_memberships_url(calendar_id: @calendar.id), as: :json
    assert_response :unauthorized

    get api_calendar_notes_url(calendar_id: @calendar.id, start_date: "2026-09-01", end_date: "2026-09-30"), as: :json
    assert_response :unauthorized
  end

  test "members cannot rename or delete a calendar" do
    authenticate_as(@member)

    patch api_calendar_url(@calendar), params: { calendar: { name: "Changed" } }, as: :json
    assert_response :forbidden

    delete api_calendar_url(@calendar), as: :json
    assert_response :forbidden
    assert Calendar.exists?(@calendar.id)
  end

  test "cross-calendar metadata, members, and notes are not exposed" do
    @other_calendar.daily_notes.create!(date: Date.new(2026, 9, 16), body: "Private note")
    authenticate_as(@owner)

    get api_calendar_url(@other_calendar), as: :json
    assert_response :not_found

    get api_calendar_memberships_url(calendar_id: @other_calendar.id), as: :json
    assert_response :not_found

    get api_calendar_notes_url(calendar_id: @other_calendar.id, start_date: "2026-09-01", end_date: "2026-09-30"), as: :json
    assert_response :not_found
    assert_not_includes response.body, "Private note"
  end

  test "expired and reused magic links cannot authenticate" do
    expired_token = @owner.issue_magic_link!
    @owner.update!(magic_link_expires_at: 1.minute.ago)
    get api_auth_magic_link_url(token: expired_token), as: :json
    assert_response :unauthorized

    reusable_token = @owner.issue_magic_link!
    get api_auth_magic_link_url(token: reusable_token), as: :json
    assert_response :success
    delete api_auth_session_url, as: :json
    assert_response :no_content

    get api_auth_magic_link_url(token: reusable_token), as: :json
    assert_response :unauthorized
  end

  test "duplicate memberships and notes remain database-protected" do
    now = Time.current
    assert_raises(ActiveRecord::RecordNotUnique) do
      ApplicationRecord.transaction(requires_new: true) do
        CalendarMembership.insert_all!([
          { calendar_id: @calendar.id, user_id: @member.id, role: "member", created_at: now, updated_at: now }
        ])
      end
    end

    @calendar.daily_notes.create!(date: Date.new(2026, 9, 16), body: "Original")
    assert_raises(ActiveRecord::RecordNotUnique) do
      ApplicationRecord.transaction(requires_new: true) do
        DailyNote.insert_all!([
          { calendar_id: @calendar.id, date: Date.new(2026, 9, 16), body: "Duplicate", created_at: now, updated_at: now }
        ])
      end
    end
  end

  test "calendar deletion removes dependent data" do
    @calendar.daily_notes.create!(date: Date.new(2026, 9, 16), body: "Delete me")
    authenticate_as(@owner)

    delete api_calendar_url(@calendar), as: :json

    assert_response :no_content
    assert_not Calendar.exists?(@calendar.id)
    assert_not CalendarMembership.exists?(calendar_id: @calendar.id)
    assert_not DailyNote.exists?(calendar_id: @calendar.id)
  end

  private

  def create_calendar(name, owner)
    calendar = Calendar.create!(name: name, creator: owner)
    calendar.calendar_memberships.create!(user: owner, role: "owner")
    calendar
  end

  def authenticate_as(user)
    token = user.issue_magic_link!
    get api_auth_magic_link_url(token: token), as: :json
    assert_response :success
  end
end
