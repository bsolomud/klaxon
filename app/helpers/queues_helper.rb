module QueuesHelper
  def queue_status_badge(status)
    config = {
      "open"   => { bg: "bg-green-100", text: "text-green-800" },
      "paused" => { bg: "bg-yellow-100", text: "text-yellow-800" },
      "closed" => { bg: "bg-gray-100", text: "text-gray-800" }
    }
    colors = config[status] || config["open"]

    tag.span(
      t("workshop_management.queues.statuses.#{status}"),
      class: "inline-flex items-center rounded-full #{colors[:bg]} px-2 py-0.5 text-xs font-medium #{colors[:text]}"
    )
  end

  def queue_entry_status_badge(status)
    config = {
      "waiting"    => { bg: "bg-yellow-100", text: "text-yellow-800" },
      "called"     => { bg: "bg-blue-100",   text: "text-blue-800" },
      "in_service" => { bg: "bg-indigo-100", text: "text-indigo-800" },
      "completed"  => { bg: "bg-green-100",  text: "text-green-800" },
      "no_show"    => { bg: "bg-red-100",    text: "text-red-800" }
    }
    colors = config[status] || config["waiting"]

    tag.span(
      t("queue_entries.statuses.#{status}"),
      class: "inline-flex items-center rounded-full #{colors[:bg]} px-2 py-0.5 text-xs font-medium #{colors[:text]}"
    )
  end
end
