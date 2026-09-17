require "test_helper"

class CalendarMembershipManagementTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email: "owner@example.com")
    @member = User.create!(email: "member@example.com")
    @outsider = User.create!(email: "outsider@example.com")
    @calendar = Calendar.create!(name: "Shared calendar", creator: @owner)
    @owner_membership = @calendar.calendar_memberships.create!(user: @owner, role: "owner")
    @member_membership = @calendar.calendar_memberships.create!(user: @member, role: "member")
  end

  test "owner can list, add, and remove members" do
    authenticate_as(@owner)

    get api_calendar_memberships_url(calendar_id: @calendar.id), as: :json
    assert_response :success
    assert_equal [ @owner.id, @member.id ].sort, response.parsed_body.fetch("members").map { |entry| entry["user_id"] }.sort

    post api_calendar_memberships_url(calendar_id: @calendar.id), params: { email: @outsider.email }, as: :json
    assert_response :created
    assert_equal "member", response.parsed_body.dig("member", "role")
    assert @calendar.reload.users.include?(@outsider)

    delete api_calendar_membership_url(calendar_id: @calendar.id, user_id: @member.id), as: :json
    assert_response :no_content
    assert_not @calendar.reload.users.include?(@member)
  end

  test "member cannot administer membership" do
    authenticate_as(@member)

    get api_calendar_memberships_url(calendar_id: @calendar.id), as: :json
    assert_response :forbidden

    post api_calendar_memberships_url(calendar_id: @calendar.id), params: { email: @outsider.email }, as: :json
    assert_response :forbidden

    delete api_calendar_membership_url(calendar_id: @calendar.id, user_id: @member.id), as: :json
    assert_response :forbidden
  end

  test "outsider cannot administer membership" do
    authenticate_as(@outsider)

    get api_calendar_memberships_url(calendar_id: @calendar.id), as: :json
    assert_response :not_found
  end

  test "owner cannot be removed" do
    authenticate_as(@owner)

    delete api_calendar_membership_url(calendar_id: @calendar.id, user_id: @owner.id), as: :json

    assert_response :forbidden
    assert @owner_membership.reload.persisted?
  end

  test "duplicate memberships are rejected and missing users are created" do
    authenticate_as(@owner)

    post api_calendar_memberships_url(calendar_id: @calendar.id), params: { email: @member.email }, as: :json
    assert_response :unprocessable_entity

    post api_calendar_memberships_url(calendar_id: @calendar.id), params: { email: "missing@example.com" }, as: :json
    assert_response :created
    assert User.exists?(email: "missing@example.com")
    assert @calendar.reload.users.exists?(email: "missing@example.com")
  end

  test "removed members immediately lose calendar access" do
    authenticate_as(@owner)
    delete api_calendar_membership_url(calendar_id: @calendar.id, user_id: @member.id), as: :json
    assert_response :no_content

    authenticate_as(@member)
    get api_calendar_url(@calendar), as: :json

    assert_response :not_found
  end

  private

  def authenticate_as(user)
    token = user.issue_magic_link!
    get api_auth_magic_link_url(token: token), as: :json
    assert_response :success
  end
end
