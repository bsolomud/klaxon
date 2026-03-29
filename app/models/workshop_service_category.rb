class WorkshopServiceCategory < ApplicationRecord
  belongs_to :workshop
  belongs_to :service_category

  has_many :service_requests, dependent: :restrict_with_exception

  validates :workshop_id, uniqueness: { scope: :service_category_id }
  validates :price_min, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :price_max, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :estimated_duration_minutes, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validate :price_max_greater_than_or_equal_to_min

  def price_display
    return I18n.t("workshops.pricing.on_request") if price_min.blank? && price_max.blank?

    suffix = price_unit.present? ? " / #{price_unit}" : ""

    if price_min.present? && price_max.present?
      if price_min == price_max
        "#{price_min.to_i} #{currency}#{suffix}"
      else
        "#{price_min.to_i}\u2013#{price_max.to_i} #{currency}#{suffix}"
      end
    elsif price_min.present?
      I18n.t("workshops.pricing.from", price: "#{price_min.to_i} #{currency}#{suffix}")
    else
      I18n.t("workshops.pricing.up_to", price: "#{price_max.to_i} #{currency}#{suffix}")
    end
  end

  def duration_display
    return nil if estimated_duration_minutes.blank?

    I18n.t("workshops.pricing.duration", minutes: estimated_duration_minutes)
  end

  private

  def price_max_greater_than_or_equal_to_min
    return if price_min.blank? || price_max.blank? || price_max >= price_min

    errors.add(:price_max, :greater_than_or_equal_to_price_min)
  end
end
