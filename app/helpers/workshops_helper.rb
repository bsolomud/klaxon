module WorkshopsHelper
  WORKSHOP_STATUS_COLORS = {
    "active" => "green", "pending" => "yellow",
    "suspended" => "red", "declined" => "gray"
  }.freeze

  def day_name(day_of_week)
    I18n.t("date.day_names")[day_of_week]
  end

  def workshop_status_indicator(workshop, open_key: "workshops.index.open_now", closed_key: "workshops.index.closed_now")
    is_open = workshop.open_now?
    dot_color = is_open ? "bg-green-500" : "bg-red-500"
    label = is_open ? t(open_key) : t(closed_key)

    tag.div(class: "flex items-center gap-1.5") do
      tag.div(class: "h-2 w-2 rounded-full shrink-0 #{dot_color}") +
        tag.span(label, class: "text-xs text-gray-500")
    end
  end

  def workshop_status_badge(status)
    status_badge(status, WORKSHOP_STATUS_COLORS, "layouts.workshop.status_#{status}")
  end
end
