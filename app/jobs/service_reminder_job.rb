# Notifies drivers when a car is due for its next service, based on the
# next_service_at_date recorded on a past ServiceRecord. Runs daily; idempotent
# via reminder_sent_at so a car is reminded only once per record.
class ServiceReminderJob < ApplicationJob
  queue_as :default

  def perform
    scope = ServiceRecord
      .where(reminder_sent_at: nil)
      .where(next_service_at_date: ..Date.current)

    # Eager-load :car (was an N+1 on record.car.user), then bulk-insert the
    # notifications and bulk-update reminder_sent_at per batch. insert_all skips
    # the delivery callback, so fan it out explicitly.
    scope.includes(:car).find_in_batches do |records|
      now = Time.current
      rows = records.map do |record|
        {
          user_id: record.car.user_id,
          notifiable_type: "ServiceRecord",
          notifiable_id: record.id,
          event: Notification.events.fetch("service_due_reminder"),
          created_at: now,
          updated_at: now
        }
      end

      ids = Notification.insert_all(rows, returning: %w[id]).rows.flatten
      ServiceRecord.where(id: records.map(&:id)).update_all(reminder_sent_at: now) # rubocop:disable Rails/SkipsModelValidations
      ActiveJob.perform_all_later(Notification.where(id: ids).map { |n| DeliverNotificationJob.new(n) })
    end
  end
end
