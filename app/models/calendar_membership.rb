class CalendarMembership < ApplicationRecord
  ROLES = %w[owner member].freeze

  belongs_to :calendar
  belongs_to :user

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :calendar_id }
end
