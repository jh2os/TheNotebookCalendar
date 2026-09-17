require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email" do
    user = User.create!(email: "  Person@Example.COM ")

    assert_equal "person@example.com", user.email
  end

  test "email is unique regardless of case" do
    User.create!(email: "person@example.com")
    duplicate = User.new(email: "PERSON@EXAMPLE.COM")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "has owned calendars and memberships" do
    assert_respond_to User.new, :owned_calendars
    assert_respond_to User.new, :calendar_memberships
    assert_respond_to User.new, :calendars
  end
end
