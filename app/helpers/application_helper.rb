module ApplicationHelper
  include Pagy::Frontend

  BADGE_COLORS = {
    "green"  => { bg: "bg-green-100",  text: "text-green-800" },
    "yellow" => { bg: "bg-yellow-100", text: "text-yellow-800" },
    "red"    => { bg: "bg-red-100",    text: "text-red-800" },
    "blue"   => { bg: "bg-blue-100",   text: "text-blue-800" },
    "indigo" => { bg: "bg-indigo-100", text: "text-indigo-800" },
    "gray"   => { bg: "bg-gray-100",   text: "text-gray-800" }
  }.freeze

  STAR_SVG_PATH = "M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"

  def star_icons(rating, size: "h-4 w-4")
    safe_join((1..5).map { |star|
      color = star <= rating.to_i ? "text-yellow-400" : "text-gray-200"
      tag.svg(tag.path(d: STAR_SVG_PATH), class: "#{size} #{color}", fill: "currentColor", viewBox: "0 0 20 20")
    })
  end

  def status_badge(status, color_map, i18n_key, default_color: "yellow")
    color = color_map[status.to_s] || default_color
    colors = BADGE_COLORS[color]

    tag.span(
      t(i18n_key),
      class: "inline-flex items-center rounded-full #{colors[:bg]} px-2 py-0.5 text-xs font-medium #{colors[:text]}"
    )
  end
end
