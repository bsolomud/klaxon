class Car < ApplicationRecord
  include Normalizable

  belongs_to :user

  enum :fuel_type, { gasoline: 0, diesel: 1, electric: 2, hybrid: 3 }
  enum :transmission, { manual: 0, automatic: 1 }

  normalizes_upcase :license_plate, :vin

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

  def display_name
    "#{year} #{make} #{model}"
  end

  private

  def nilify_blank_vin
    self.vin = nil if vin.blank?
  end
end
