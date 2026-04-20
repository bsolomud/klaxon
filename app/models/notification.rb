class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  enum :event, {
    workshop_approved: 0,
    workshop_declined: 1,
    service_request_created: 2,
    service_request_accepted: 3,
    service_request_rejected: 4,
    service_request_started: 5,
    service_request_completed: 6,
    car_transfer_requested: 7,
    car_transfer_approved: 8,
    car_transfer_rejected: 9,
    car_transfer_cancelled: 10,
    car_transfer_expired: 11,
    queue_called: 12
  }

  validates :event, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def mark_as_read!
    return if read_at.present?

    update!(read_at: Time.current)
  end

  def target_path
    return unless notifiable

    case notifiable_type
    when "ServiceRequest"
      Rails.application.routes.url_helpers.service_request_path(notifiable_id)
    when "CarTransfer"
      Rails.application.routes.url_helpers.car_transfer_path(token: notifiable.token)
    when "Workshop"
      Rails.application.routes.url_helpers.my_workshops_path
    when "QueueEntry"
      Rails.application.routes.url_helpers.queue_entry_path(notifiable_id)
    end
  end
end
