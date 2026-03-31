module ServiceRequestsHelper
  SERVICE_REQUEST_STATUS_COLORS = {
    "pending" => "yellow", "accepted" => "blue", "rejected" => "red",
    "in_progress" => "indigo", "completed" => "green"
  }.freeze

  def service_request_status_badge(status)
    status_badge(status, SERVICE_REQUEST_STATUS_COLORS, "service_requests.statuses.#{status}")
  end
end
