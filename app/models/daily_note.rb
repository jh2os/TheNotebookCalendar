class DailyNote < ApplicationRecord
  belongs_to :calendar

  validates :date, presence: true, uniqueness: { scope: :calendar_id }
  validates :body, presence: true
end
