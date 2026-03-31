module ApplicationHelper
  BADGE_COLORS = {
    "green"  => { bg: "bg-green-100",  text: "text-green-800" },
    "yellow" => { bg: "bg-yellow-100", text: "text-yellow-800" },
    "red"    => { bg: "bg-red-100",    text: "text-red-800" },
    "blue"   => { bg: "bg-blue-100",   text: "text-blue-800" },
    "indigo" => { bg: "bg-indigo-100", text: "text-indigo-800" },
    "gray"   => { bg: "bg-gray-100",   text: "text-gray-800" }
  }.freeze

  def status_badge(status, color_map, i18n_key, default_color: "yellow")
    color = color_map[status.to_s] || default_color
    colors = BADGE_COLORS[color]

    tag.span(
      t(i18n_key),
      class: "inline-flex items-center rounded-full #{colors[:bg]} px-2 py-0.5 text-xs font-medium #{colors[:text]}"
    )
  end
end
