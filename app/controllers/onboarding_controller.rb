class OnboardingController < ApplicationController
  def update
    case params[:flag]
    when "welcome_dismissed"
      current_user.dismiss_welcome_banner!
    end

    head :ok
  end
end
