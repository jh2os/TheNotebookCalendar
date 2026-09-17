class Calendar < ApplicationRecord
  belongs_to :creator,
             class_name: "User",
             foreign_key: :created_by_id,
             inverse_of: :owned_calendars
  has_many :calendar_memberships, dependent: :destroy
  has_many :users, through: :calendar_memberships
  has_many :daily_notes, dependent: :destroy

  validates :name, presence: true
end
