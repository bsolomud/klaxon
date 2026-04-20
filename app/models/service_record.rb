class ServiceRecord < ApplicationRecord
  belongs_to :service_request

  has_one :car, through: :service_request
  has_one :workshop, through: :service_request
  has_one :workshop_service_category, through: :service_request

  validates :summary, presence: true
  validates :completed_at, presence: true
  validate :odometer_not_backwards

  before_validation :set_completed_at, on: :create

  after_create :update_car_odometer

  def total_cost
    (labor_cost || 0) + (parts_cost || 0)
  end

  private

  def set_completed_at
    self.completed_at ||= Time.current
  end

  def odometer_not_backwards
    return if odometer_at_service.blank?
    return unless car&.odometer.present?
    return if odometer_at_service >= car.odometer

    errors.add(:odometer_at_service, :less_than_current)
  end

  def update_car_odometer
    return unless odometer_at_service.present?

    car.update!(odometer: odometer_at_service)
  end
end
