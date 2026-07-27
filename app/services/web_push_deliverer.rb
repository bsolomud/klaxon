# Sends a browser push notification to each of a user's push subscriptions.
# No-op when VAPID keys are not configured or the user opted out of push.
class WebPushDeliverer
  def initialize(notification)
    @notification = notification
    @user = notification.user
  end

  def deliver
    return unless self.class.configured? && @user.push_notifications?

    @user.push_subscriptions.find_each { |subscription| send_to(subscription) }
  end

  def self.configured?
    vapid = Rails.application.config.x.vapid
    vapid[:public_key].present? && vapid[:private_key].present?
  end

  private

  def payload
    {
      title: "AULABS",
      body: I18n.t("notifications.events.#{@notification.event}"),
      path: @notification.target_path
    }.compact.to_json
  end

  def send_to(subscription)
    vapid = Rails.application.config.x.vapid
    WebPush.payload_send(
      message: payload,
      endpoint: subscription.endpoint,
      p256dh: subscription.p256dh_key,
      auth: subscription.auth_key,
      vapid: { subject: vapid[:subject], public_key: vapid[:public_key], private_key: vapid[:private_key] }
    )
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    subscription.destroy
  end
end
