require "application_system_test_case"

class CoreUserFlowsTest < ApplicationSystemTestCase
  setup do
    ActionMailer::Base.deliveries.clear
    @owner = User.create!(email: "owner@example.com")
    @member = User.create!(email: "member@example.com")
  end

  test "new user can log in, create a calendar, write a note, and reload" do
    visit "/"
    fill_in "Email", with: "new-user@example.com"
    click_button "Send login link"
    assert_text "If the email is valid, a login link has been sent."

    visit magic_link_path_for_last_email
    assert_text "Create a calendar to get started."

    fill_in "Calendar name", with: "Personal"
    click_button "Create"
    assert_text "Personal"
    assert_selector 'textarea[aria-label="Daily note"]:not([disabled])'

    click_button "#{Date.current.day}"
    find('textarea[aria-label="Daily note"]').set("Remember the important thing")
    click_button "Save note"
    assert_selector 'textarea[aria-label="Daily note"]'
    assert_equal "Remember the important thing", find('textarea[aria-label="Daily note"]').value

    page.refresh
    assert_selector 'textarea[aria-label="Daily note"]'
    assert_equal "Remember the important thing", find('textarea[aria-label="Daily note"]').value
  end

  test "existing user can navigate views, edit notes, change theme, and log out" do
    calendar = create_calendar("Existing calendar", @owner)
    calendar.daily_notes.create!(date: Date.current, body: "Existing note")
    sign_in_as(@owner)

    assert_text "Existing calendar"
    assert_selector 'textarea[aria-label="Daily note"]:not([disabled])'
    assert_equal "Existing note", find('textarea[aria-label="Daily note"]').value
    click_button "Week"
    assert_selector ".week-grid"
    click_button "Next week"
    click_button "Month"
    click_button "Dark"
    assert_equal "dark", page.evaluate_script("document.documentElement.dataset.theme")
    click_button "Log out"
    assert_text "Sign in with a magic link"
  end

  test "owner can share a calendar and member cannot administer membership" do
    calendar = create_calendar("Shared calendar", @owner)
    sign_in_as(@owner)

    fill_in "Add member", with: @member.email
    click_button "Add member"
    assert_text @member.email

    click_button "Log out"
    sign_in_as(@member)
    assert_text "Shared calendar"
    assert_no_text "Add member"
    assert_no_button "Remove"
  end

  test "non-member cannot access a private calendar" do
    create_calendar("Private calendar", @owner)
    sign_in_as(@member)

    assert_text "Create a calendar to get started."
    assert_no_text "Private calendar"
  end

  private

  def create_calendar(name, owner)
    calendar = Calendar.create!(name: name, creator: owner)
    calendar.calendar_memberships.create!(user: owner, role: "owner")
    calendar
  end

  def sign_in_as(user)
    visit "/"
    fill_in "Email", with: user.email
    click_button "Send login link"
    assert_text "If the email is valid, a login link has been sent."
    visit magic_link_path_for_last_email
    assert_no_text "Sign in with a magic link"
  end

  def magic_link_path_for_last_email
    email = ActionMailer::Base.deliveries.last
    body = email.parts.map(&:decoded).join("\n")
    token = body.match(%r{[?&]magic_link=([A-Za-z0-9_-]+)})[1]
    "/?magic_link=#{token}"
  end
end
