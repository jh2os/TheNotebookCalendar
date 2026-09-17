require "test_helper"

class DailyNoteTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email: "notes@example.com")
    @calendar = Calendar.create!(name: "Notes calendar", creator: user)
  end

  test "uses a date-only value" do
    note = DailyNote.create!(calendar: @calendar, date: "2026-09-16", body: "Write tests")

    assert_instance_of Date, note.date
    assert_equal Date.new(2026, 9, 16), note.date
  end

  test "prevents duplicate notes for a calendar day in Rails and PostgreSQL" do
    DailyNote.create!(calendar: @calendar, date: Date.new(2026, 9, 16), body: "First note")
    duplicate = DailyNote.new(calendar: @calendar, date: Date.new(2026, 9, 16), body: "Second note")

    assert_not duplicate.valid?
    assert_raises(ActiveRecord::RecordNotUnique) do
      DailyNote.insert_all!([ { calendar_id: @calendar.id, date: Date.new(2026, 9, 16), body: "Second note", created_at: Time.current, updated_at: Time.current } ])
    end
  end

  test "requires a body" do
    note = DailyNote.new(calendar: @calendar, date: Date.new(2026, 9, 16))

    assert_not note.valid?
    assert_includes note.errors[:body], "can't be blank"
  end
end
