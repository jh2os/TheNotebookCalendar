require "test_helper"

class CalendarTest < ActiveSupport::TestCase
  test "requires a name and creator" do
    calendar = Calendar.new

    assert_not calendar.valid?
    assert_includes calendar.errors[:name], "can't be blank"
    assert_includes calendar.errors[:creator], "must exist"
  end

  test "belongs to its creator and has notes and memberships" do
    assert_respond_to Calendar.new, :creator
    assert_respond_to Calendar.new, :calendar_memberships
    assert_respond_to Calendar.new, :users
    assert_respond_to Calendar.new, :daily_notes
  end
end
