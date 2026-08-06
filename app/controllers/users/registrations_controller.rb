class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  private

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :middle_name, :phone_number])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :middle_name, :phone_number])
  end

  # Record whether the new user signed up as a driver or a workshop operator so
  # after_sign_in_path_for (ApplicationController) can route operators to create
  # their workshop once they confirm and sign in.
  def build_resource(hash = {})
    super
    resource.onboarding_flags = resource.onboarding_flags.merge("intent" => intent_param) if intent_param
  end

  def intent_param
    params[:intent] if %w[driver operator].include?(params[:intent])
  end
end
