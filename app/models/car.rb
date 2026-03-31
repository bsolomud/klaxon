class Car < ApplicationRecord
  belongs_to :user

  has_many :car_ownership_records, dependent: :destroy
  has_many :car_transfers, dependent: :restrict_with_exception
  has_many :service_requests, dependent: :restrict_with_exception
  has_many :service_records, through: :service_requests

  enum :fuel_type, { gasoline: 0, diesel: 1, electric: 2, hybrid: 3 }
  enum :transmission, { manual: 0, automatic: 1 }

  normalizes :license_plate, with: ->(v) { v&.strip&.upcase }
  normalizes :vin, with: ->(v) { v&.strip&.upcase }

  validates :make, presence: true
  validates :model, presence: true
  validates :year, presence: true,
            numericality: { only_integer: true, greater_than: 1885 }
  validates :license_plate, presence: true,
            uniqueness: { case_sensitive: false }
  validates :fuel_type, presence: true
  validates :vin, length: { is: 17 }, uniqueness: true, allow_nil: true
  validates :engine_volume, absence: { message: :not_applicable_for_electric },
            if: :electric?

  before_validation :nilify_blank_vin

  after_create :create_initial_ownership_record

  def display_name
    "#{year} #{make} #{model}"
  end

  def vin_duplicate_for_another_user?
    vin.present? &&
      errors[:vin].any? &&
      Car.where.not(user_id: user_id).exists?(vin: vin)
  end

  private

  def nilify_blank_vin
    self.vin = nil if vin.blank?
  end

  def create_initial_ownership_record
    car_ownership_records.create!(
      user: user,
      started_at: Time.current
    )
  end
end
