require "test_helper"

class CalendarMembershipTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "member@example.com")
    @calendar = Calendar.create!(name: "Shared calendar", creator: @user)
  end

  test "accepts owner and member roles" do
    assert_predicate CalendarMembership.new(calendar: @calendar, user: @user, role: "owner"), :valid?
    assert_predicate CalendarMembership.new(calendar: @calendar, user: @user, role: "member"), :valid?
  end

  test "rejects unknown roles" do
    membership = CalendarMembership.new(calendar: @calendar, user: @user, role: "admin")

    assert_not membership.valid?
    assert_includes membership.errors[:role], "is not included in the list"
  end

  test "prevents duplicate memberships in Rails and PostgreSQL" do
    CalendarMembership.create!(calendar: @calendar, user: @user, role: "owner")
    duplicate = CalendarMembership.new(calendar: @calendar, user: @user, role: "member")

    assert_not duplicate.valid?
    assert_raises(ActiveRecord::RecordNotUnique) do
      CalendarMembership.insert_all!([ { calendar_id: @calendar.id, user_id: @user.id, role: "member", created_at: Time.current, updated_at: Time.current } ])
    end
  end
end
