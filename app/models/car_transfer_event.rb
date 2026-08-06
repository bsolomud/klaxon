class CarTransferEvent < ApplicationRecord
  belongs_to :car_transfer
  belongs_to :actor, class_name: "User", optional: true

  enum :event_type, {
    transfer_requested: 0,
    notification_sent: 1,
    approved: 2,
    rejected: 3,
    cancelled: 4,
    expired: 5,
    ownership_transferred: 6
  }

  validates :event_type, presence: true

  def readonly?
    persisted?
  end

  before_destroy { throw :abort }
end
