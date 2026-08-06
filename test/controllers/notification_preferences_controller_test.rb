require "test_helper"

class NotificationPreferencesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "update stores email and push preferences" do
    patch notification_preferences_path, params: { email: "1", push: "0" }
    @user.reload
    assert @user.email_notifications?
    assert_not @user.push_notifications?
    assert_redirected_to notifications_path
  end

  test "unchecked boxes disable channels" do
    patch notification_preferences_path, params: {}
    @user.reload
    assert_not @user.email_notifications?
    assert_not @user.push_notifications?
  end

  test "requires authentication" do
    sign_out @user
    patch notification_preferences_path, params: { email: "1" }
    assert_redirected_to new_user_session_path
  end
end
