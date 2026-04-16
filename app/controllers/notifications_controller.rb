class NotificationsController < ApplicationController
  before_action :set_notification, only: [:update]

  def index
    @notifications = current_user.notifications.recent.includes(:notifiable).limit(100)
  end

  def update
    @notification.mark_as_read!
    redirect_to @notification.target_path || notifications_path, notice: t(".success")
  end

  def update_all
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_to notifications_path, notice: t(".success")
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
