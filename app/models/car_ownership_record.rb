class CarOwnershipRecord < ApplicationRecord
  belongs_to :car
  belongs_to :user
  belongs_to :car_transfer, optional: true

  validates :started_at, presence: true

  scope :current, -> { where(ended_at: nil) }

  def readonly?
    persisted? && ended_at_was.present?
  end
end
