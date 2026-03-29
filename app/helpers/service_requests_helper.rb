module ServiceRequestsHelper
  def service_request_status_badge(status)
    config = {
      "pending"     => { bg: "bg-yellow-100", text: "text-yellow-800" },
      "accepted"    => { bg: "bg-blue-100",   text: "text-blue-800" },
      "rejected"    => { bg: "bg-red-100",    text: "text-red-800" },
      "in_progress" => { bg: "bg-indigo-100", text: "text-indigo-800" },
      "completed"   => { bg: "bg-green-100",  text: "text-green-800" }
    }
    colors = config[status] || config["pending"]

    tag.span(
      t("service_requests.statuses.#{status}"),
      class: "inline-flex items-center rounded-full #{colors[:bg]} px-2 py-0.5 text-xs font-medium #{colors[:text]}"
    )
  end
end
