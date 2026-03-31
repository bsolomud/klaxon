class WorkshopServiceCategory < ApplicationRecord
  include PriceFormattable

  belongs_to :workshop
  belongs_to :service_category

  has_many :service_requests, dependent: :restrict_with_exception

  validates :workshop_id, uniqueness: { scope: :service_category_id }
  validates :price_min, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :price_max, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :estimated_duration_minutes, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validate :price_max_greater_than_or_equal_to_min

  def display_price
    format_price(price_min, price_max, currency, unit: price_unit)
  end

  def display_duration
    return nil if estimated_duration_minutes.blank?

    I18n.t("workshops.pricing.duration", minutes: estimated_duration_minutes)
  end

  private

  def price_max_greater_than_or_equal_to_min
    return if price_min.blank? || price_max.blank? || price_max >= price_min

    errors.add(:price_max, :greater_than_or_equal_to_price_min)
  end
end
