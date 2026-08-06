class NotificationPreferencesController < ApplicationController
  def update
    current_user.update!(notification_preferences: {
      "email" => params[:email] == "1",
      "push" => params[:push] == "1"
    })
    redirect_to notifications_path, notice: t("notification_preferences.update.success")
  end
end
