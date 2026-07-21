require "test_helper"

class Users::OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
    Rails.application.env_config.delete("omniauth.auth")
  end

  def stub_google(email:, uid: "g-123", first: "Оля", last: "Коваль")
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: uid,
      info: { email: email, first_name: first, last_name: last }
    )
    OmniAuth.config.mock_auth[:google_oauth2] = auth
    Rails.application.env_config["omniauth.auth"] = auth
  end

  test "creates a confirmed user and signs them in" do
    stub_google(email: "newg@example.com")
    assert_difference "User.count", 1 do
      get user_google_oauth2_omniauth_callback_path
    end
    user = User.find_by(email: "newg@example.com")
    assert_equal "google_oauth2", user.provider
    assert user.confirmed?
    assert_redirected_to root_path
  end

  test "links Google to an existing password account" do
    existing = users(:one)
    stub_google(email: existing.email, uid: "g-999")
    assert_no_difference "User.count" do
      get user_google_oauth2_omniauth_callback_path
    end
    assert_equal "g-999", existing.reload.uid
  end
end
