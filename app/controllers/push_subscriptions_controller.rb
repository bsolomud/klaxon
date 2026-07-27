class PushSubscriptionsController < ApplicationController
  def create
    current_user.push_subscriptions.find_or_create_by!(endpoint: subscription_params[:endpoint]) do |sub|
      sub.p256dh_key = subscription_params[:p256dh_key]
      sub.auth_key = subscription_params[:auth_key]
    end
    head :created
  end

  private

  def subscription_params
    params.require(:push_subscription).permit(:endpoint, :p256dh_key, :auth_key)
  end
end
