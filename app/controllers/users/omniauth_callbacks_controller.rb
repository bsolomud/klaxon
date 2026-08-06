class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      flash[:notice] = t("devise.sessions.signed_in")
      sign_in_and_redirect @user, event: :authentication
    else
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.to_sentence
    end
  end

  def failure
    redirect_to new_user_session_path, alert: t("devise.shared.oauth.failure")
  end
end
