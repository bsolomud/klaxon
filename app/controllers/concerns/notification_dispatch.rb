module NotificationDispatch
  extend ActiveSupport::Concern

  private

  def dispatch_notification(recipients:, notifiable:, event:, mailer: nil)
    mailer&.deliver_later

    Array(recipients).each do |recipient|
      if recipient.is_a?(Integer)
        Notification.create!(user_id: recipient, notifiable: notifiable, event: event)
      else
        Notification.create!(user: recipient, notifiable: notifiable, event: event)
      end
    end
  end
end
