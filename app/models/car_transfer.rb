class CarTransfer < ApplicationRecord
  belongs_to :car
  belongs_to :from_user, class_name: "User"
  belongs_to :to_user, class_name: "User"

  has_many :car_transfer_events, dependent: :restrict_with_exception

  enum :status, { requested: 0, approved: 1, rejected: 2, cancelled: 3, expired: 4 }

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :generate_token, on: :create
  before_validation :set_expires_at, on: :create

  scope :active, -> { where(status: :requested) }

  def expired?
    expires_at < Time.current
  end

  def to_param
    token
  end

  def approve!(actor:)
    ActiveRecord::Base.transaction do
      approved!
      car.update!(user_id: to_user_id)
      car.car_ownership_records.current.update_all(ended_at: Time.current)
      car.car_ownership_records.create!(
        user_id: to_user_id,
        started_at: Time.current,
        car_transfer_id: id
      )
      car_transfer_events.create!(event_type: :approved, actor: actor)
      car_transfer_events.create!(
        event_type: :ownership_transferred,
        metadata: { from_user_id: from_user_id, to_user_id: to_user_id }
      )
    end
  end

  def reject!(actor:)
    ActiveRecord::Base.transaction do
      rejected!
      car_transfer_events.create!(event_type: :rejected, actor: actor)
    end
  end

  def cancel!(actor:)
    ActiveRecord::Base.transaction do
      cancelled!
      car_transfer_events.create!(event_type: :cancelled, actor: actor)
    end
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expires_at
    self.expires_at ||= 14.days.from_now
  end
end
