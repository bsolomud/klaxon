# Fans a notification out to the driver's out-of-app channels (web push always;
# SMS for a few high-urgency events). In-app + email are handled elsewhere.
class DeliverNotificationJob < ApplicationJob
  queue_as :default

  URGENT_SMS_EVENTS = %w[queue_called service_due_reminder].freeze

  def perform(notification)
    WebPushDeliverer.new(notification).deliver
    deliver_sms(notification)
  end

  private

  def deliver_sms(notification)
    user = notification.user
    return unless URGENT_SMS_EVENTS.include?(notification.event) && user.phone_number.present?

    Sms.deliver(to: user.phone_number, body: I18n.t("notifications.events.#{notification.event}"))
  end
end
