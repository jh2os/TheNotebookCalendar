class User < ApplicationRecord
  normalizes :email, with: ->(email) { email.strip.downcase }

  has_many :owned_calendars,
           class_name: "Calendar",
           foreign_key: :created_by_id,
           inverse_of: :creator,
           dependent: :restrict_with_error
  has_many :calendar_memberships, dependent: :destroy
  has_many :calendars, through: :calendar_memberships

  validates :email, presence: true, uniqueness: { case_sensitive: false }
end
