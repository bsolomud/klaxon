require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @workshop = workshops(:one)
  end

  test "is valid with user, notifiable, and event" do
    notification = Notification.new(user: @user, notifiable: @workshop, event: :workshop_approved)
    assert notification.valid?
  end

  test "requires user" do
    notification = Notification.new(notifiable: @workshop, event: :workshop_approved)
    assert_not notification.valid?
  end

  test "requires notifiable" do
    notification = Notification.new(user: @user, event: :workshop_approved)
    assert_not notification.valid?
  end

  test "requires event" do
    notification = Notification.new(user: @user, notifiable: @workshop)
    assert_not notification.valid?
  end

  test "unread scope returns notifications with nil read_at" do
    unread = Notification.unread
    assert_includes unread, notifications(:two)
    assert_not_includes unread, notifications(:one)
  end

  test "recent scope orders by created_at desc" do
    all_notifs = Notification.recent
    assert all_notifs.to_a == all_notifs.sort_by { |n| -n.created_at.to_i }
  end

  test "mark_as_read! sets read_at timestamp" do
    notification = notifications(:two)
    assert_nil notification.read_at
    notification.mark_as_read!
    assert_not_nil notification.read_at
  end

  test "mark_as_read! is idempotent" do
    notification = notifications(:one)
    original_read_at = notification.read_at
    notification.mark_as_read!
    assert_equal original_read_at.to_i, notification.reload.read_at.to_i
  end

  test "target_path returns workshop path for Workshop notifiable" do
    notification = Notification.new(user: @user, notifiable: @workshop, event: :workshop_approved)
    assert_equal "/my_workshops", notification.target_path
  end

  test "target_path returns service_request path for ServiceRequest notifiable" do
    sr = service_requests(:pending_request)
    notification = Notification.new(user: @user, notifiable: sr, event: :service_request_created)
    assert_equal "/service_requests/#{sr.id}", notification.target_path
  end

  test "target_path returns car_transfer path for CarTransfer notifiable" do
    transfer = car_transfers(:pending_transfer)
    notification = Notification.new(user: @user, notifiable: transfer, event: :car_transfer_requested)
    assert_equal "/car_transfers/#{transfer.token}", notification.target_path
  end

  test "target_path returns queue_entry path for QueueEntry notifiable" do
    entry = queue_entries(:waiting_entry)
    notification = Notification.new(user: @user, notifiable: entry, event: :queue_called)
    assert_equal "/queue_entries/#{entry.id}", notification.target_path
  end
end
