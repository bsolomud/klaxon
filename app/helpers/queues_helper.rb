module QueuesHelper
  QUEUE_STATUS_COLORS = {
    "open" => "green", "paused" => "yellow", "closed" => "gray"
  }.freeze

  QUEUE_ENTRY_STATUS_COLORS = {
    "waiting" => "yellow", "called" => "blue", "in_service" => "indigo",
    "completed" => "green", "no_show" => "red"
  }.freeze

  def queue_status_badge(status)
    status_badge(status, QUEUE_STATUS_COLORS, "workshop_management.queues.statuses.#{status}")
  end

  def queue_entry_status_badge(status)
    status_badge(status, QUEUE_ENTRY_STATUS_COLORS, "queue_entries.statuses.#{status}")
  end
end
