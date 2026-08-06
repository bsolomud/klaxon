module QueuesHelper
  def queue_status_badge(status)
    status_badge(status, ServiceQueue::STATUS_COLORS, "workshop_management.queues.statuses.#{status}")
  end

  def queue_entry_status_badge(status)
    status_badge(status, QueueEntry::STATUS_COLORS, "queue_entries.statuses.#{status}")
  end
end
