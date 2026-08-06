module ServiceRequestsHelper
  def service_request_status_badge(status)
    status_badge(status, ServiceRequest::STATUS_COLORS, "service_requests.statuses.#{status}")
  end
end
