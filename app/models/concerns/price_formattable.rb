module PriceFormattable
  extend ActiveSupport::Concern

  private

  def format_price(min, max, currency, unit: nil)
    return I18n.t("workshops.pricing.on_request") if min.blank? && max.blank?

    suffix = unit.present? ? " / #{unit}" : ""

    if min.present? && max.present?
      if min == max
        "#{min.to_i} #{currency}#{suffix}"
      else
        "#{min.to_i}\u2013#{max.to_i} #{currency}#{suffix}"
      end
    elsif min.present?
      I18n.t("workshops.pricing.from", price: "#{min.to_i} #{currency}#{suffix}")
    else
      I18n.t("workshops.pricing.up_to", price: "#{max.to_i} #{currency}#{suffix}")
    end
  end
end
