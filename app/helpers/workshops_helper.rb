module WorkshopsHelper
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
    config = {
      "active"    => { bg: "bg-green-100",  text: "text-green-800" },
      "pending"   => { bg: "bg-yellow-100", text: "text-yellow-800" },
      "suspended" => { bg: "bg-red-100",    text: "text-red-800" },
      "declined"  => { bg: "bg-gray-100",   text: "text-gray-800" }
    }
    colors = config[status] || config["pending"]

    tag.span(
      t("layouts.workshop.status_#{status}"),
      class: "inline-flex items-center rounded-full #{colors[:bg]} px-2 py-0.5 text-[10px] font-medium #{colors[:text]}"
    )
  end
end
