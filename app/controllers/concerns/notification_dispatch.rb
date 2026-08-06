module NotificationDispatch
  extend ActiveSupport::Concern

  private

  def dispatch_notification(recipients:, notifiable:, event:, mailer: nil)
    mailer&.deliver_later

    now = Time.current
    rows = Array(recipients).map do |recipient|
      {
        user_id: recipient.is_a?(Integer) ? recipient : recipient.id,
        notifiable_type: notifiable.class.polymorphic_name,
        notifiable_id: notifiable.id,
        event: Notification.events.fetch(event.to_s),
        created_at: now,
        updated_at: now
      }
    end
    return if rows.empty?

    # One INSERT instead of N. insert_all skips after_create_commit, so fan the
    # push/SMS delivery out explicitly for the inserted rows.
    ids = Notification.insert_all(rows, returning: %w[id]).rows.flatten
    ActiveJob.perform_all_later(Notification.where(id: ids).map { |n| DeliverNotificationJob.new(n) })
  end
end
