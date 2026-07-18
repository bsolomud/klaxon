module PriceFormattable
  extend ActiveSupport::Concern

  # When max is more than this multiple of min, a bare range (e.g. 500–5000)
  # is too vague to help a driver decide, so we show "from <min>" instead.
  WIDE_RANGE_FACTOR = 4

  private

  def format_price(min, max, currency, unit: nil)
    return I18n.t("workshops.pricing.on_request") if min.blank? && max.blank?

    suffix = unit.present? ? " / #{unit}" : ""

    if min.present? && max.present?
      if min == max
        "#{min.to_i} #{currency}#{suffix}"
      elsif max.to_i > min.to_i * WIDE_RANGE_FACTOR
        I18n.t("workshops.pricing.from", price: "#{min.to_i} #{currency}#{suffix}")
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
