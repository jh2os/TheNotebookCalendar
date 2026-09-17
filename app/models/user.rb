class User < ApplicationRecord
  MAGIC_LINK_LIFETIME = 15.minutes

  normalizes :email, with: ->(email) { email.strip.downcase }

  has_many :owned_calendars,
           class_name: "Calendar",
           foreign_key: :created_by_id,
           inverse_of: :creator,
           dependent: :restrict_with_error
  has_many :calendar_memberships, dependent: :destroy
  has_many :calendars, through: :calendar_memberships

  validates :email, presence: true, uniqueness: { case_sensitive: false }

  def issue_magic_link!
    raw_token = SecureRandom.urlsafe_base64(32)

    update!(
      magic_link_digest: self.class.digest_magic_link(raw_token),
      magic_link_expires_at: MAGIC_LINK_LIFETIME.from_now,
      magic_link_used_at: nil
    )

    raw_token
  end

  def authenticate_magic_link!(raw_token)
    return false if magic_link_used_at.present?
    return false if magic_link_expires_at.blank? || magic_link_expires_at <= Time.current
    return false unless ActiveSupport::SecurityUtils.secure_compare(
      magic_link_digest.to_s,
      self.class.digest_magic_link(raw_token)
    )

    update!(magic_link_used_at: Time.current)
    true
  end

  def self.digest_magic_link(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end
end
