require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @read_notification = notifications(:one)
    @unread_notification = notifications(:two)
    sign_in @user
  end

  test "index shows notifications for current user" do
    get notifications_path
    assert_response :success
    assert_select "h1", text: I18n.t("notifications.index.title")
  end

  test "index requires authentication" do
    sign_out @user
    get notifications_path
    assert_redirected_to new_user_session_path
  end

  test "index scopes to current user" do
    other_notification = notifications(:three)
    get notifications_path
    assert_response :success
    assert_select "[data-notification-id=\"#{other_notification.id}\"]", false
  end

  test "update marks notification as read and redirects to target" do
    assert_nil @unread_notification.read_at

    patch notification_path(@unread_notification)

    assert_not_nil @unread_notification.reload.read_at
    assert_redirected_to @unread_notification.target_path
  end

  test "update is idempotent on already read notification" do
    original_read_at = @read_notification.read_at

    patch notification_path(@read_notification)

    assert_in_delta original_read_at, @read_notification.reload.read_at, 1.second
  end

  test "update cannot mark another user's notification" do
    other = notifications(:three)
    patch notification_path(other)
    assert_response :not_found
    assert_nil other.reload.read_at
  end

  test "update_all marks all unread as read" do
    assert @user.notifications.unread.any?

    patch update_all_notifications_path

    assert_equal 0, @user.notifications.unread.count
    assert_redirected_to notifications_path
  end

  test "update_all does not affect other users" do
    other_user_unread = notifications(:three)
    patch update_all_notifications_path
    assert_nil other_user_unread.reload.read_at
  end
end
