# Notifies drivers when a car is due for its next service, based on the
# next_service_at_date recorded on a past ServiceRecord. Runs daily; idempotent
# via reminder_sent_at so a car is reminded only once per record.
class ServiceReminderJob < ApplicationJob
  queue_as :default

  def perform
    ServiceRecord
      .where(reminder_sent_at: nil)
      .where(next_service_at_date: ..Date.current)
      .find_each do |record|
        Notification.create!(user: record.car.user, notifiable: record, event: :service_due_reminder)
        record.update_column(:reminder_sent_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
      end
  end
end
