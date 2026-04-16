require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  setup do
    ActionCable.server.config.cable = { "adapter" => "async" }
  end

  teardown do
    ActionCable.server.config.cable = { "adapter" => "test" }
  end

  # Sign in through the Devise form so the session cookie is set in the
  # current Capybara session. Asserts on a post-login nav link rather than a
  # header string that also appears when signed out.
  def sign_in_user(user, password: "password")
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: password
    find('input[type="submit"]').click
    assert_text I18n.t("layouts.application.nav.my_cars")
  end
end
