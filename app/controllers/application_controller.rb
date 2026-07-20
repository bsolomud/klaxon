class ApplicationController < ActionController::Base
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :switch_locale
  before_action :authenticate_user!
  before_action :set_unread_notifications_count

  private

  def switch_locale(&action)
    locale = resolved_locale
    persist_locale(locale)
    I18n.with_locale(locale, &action)
  end

  def resolved_locale
    candidate = params[:locale].presence || current_user&.locale.presence || locale_from_header
    valid_locale?(candidate) ? candidate.to_s : I18n.default_locale.to_s
  end

  def locale_from_header
    request.env["HTTP_ACCEPT_LANGUAGE"].to_s.scan(/[a-zA-Z]{2}/).map(&:downcase).find { |code| valid_locale?(code) }
  end

  def valid_locale?(code)
    code.present? && I18n.available_locales.map(&:to_s).include?(code.to_s)
  end

  def persist_locale(locale)
    return unless user_signed_in? && params[:locale].present?
    return if current_user.locale == locale

    current_user.update!(locale: locale)
  end

  def set_unread_notifications_count
    @unread_notifications_count = current_user.notifications.unread.count if user_signed_in?
  end

  def require_workshop_access!(workshop = @workshop)
    redirect_to root_path, alert: t("authorization.access_denied") unless current_user.manages_workshop?(workshop)
  end

  # Operators who signed up with that intent but have not created a workshop yet
  # are sent straight to the workshop creation form on sign in.
  def after_sign_in_path_for(resource)
    if resource.is_a?(User) && resource.onboarding_flags["intent"] == "operator" && !resource.workshops.exists?
      new_workshop_path
    else
      super
    end
  end
end
