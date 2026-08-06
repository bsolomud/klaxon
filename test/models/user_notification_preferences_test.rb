require "test_helper"

class UserNotificationPreferencesTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "email and push default to enabled" do
    assert @user.email_notifications?
    assert @user.push_notifications?
  end

  test "respects stored preferences" do
    @user.update!(notification_preferences: { "email" => false, "push" => false })
    assert_not @user.email_notifications?
    assert_not @user.push_notifications?
  end

  test "missing key falls back to enabled" do
    @user.update!(notification_preferences: { "email" => false })
    assert_not @user.email_notifications?
    assert @user.push_notifications?
  end
end
