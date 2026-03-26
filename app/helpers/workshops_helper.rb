module WorkshopsHelper
  DAY_NAMES = %w[sunday monday tuesday wednesday thursday friday saturday].freeze

  def day_name(day_of_week)
    t("workshops.days.#{DAY_NAMES[day_of_week]}")
  end

  def workshop_status_indicator(workshop, open_key: "workshops.index.open_now", closed_key: "workshops.index.closed_now")
    dot_color = workshop.open_now? ? "bg-green-500" : "bg-red-500"
    label = workshop.open_now? ? t(open_key) : t(closed_key)

    tag.div(class: "flex items-center gap-1.5") do
      tag.div(class: "h-2 w-2 rounded-full shrink-0 #{dot_color}") +
        tag.span(label, class: "text-xs text-gray-500")
    end
  end
end
