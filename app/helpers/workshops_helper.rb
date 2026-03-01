module WorkshopsHelper
  DAY_NAMES = %w[sunday monday tuesday wednesday thursday friday saturday].freeze

  def day_name(day_of_week)
    t("workshops.days.#{DAY_NAMES[day_of_week]}")
  end
end
