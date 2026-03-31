require "test_helper"

class QueueEntriesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:driver_no_workshops)
    @queue = service_queues(:open_queue)
    sign_in @user
  end

  # --- Create ---

  test "create joins an open queue" do
    assert_difference "QueueEntry.count", 1 do
      post queue_entries_path, params: { queue_id: @queue.id }
    end

    entry = QueueEntry.last
    assert_equal @queue.id, entry.queue_id
    assert_equal @user.id, entry.user_id
    assert entry.waiting?
    assert_redirected_to queue_entry_path(entry)
  end

  test "create assigns sequential position" do
    existing_max = @queue.queue_entries.maximum(:position)
    post queue_entries_path, params: { queue_id: @queue.id }
    entry = QueueEntry.last
    assert_equal existing_max + 1, entry.position
  end

  test "create with optional car_id" do
    car = cars(:other_user_car)
    post queue_entries_path, params: { queue_id: @queue.id, car_id: car.id }
    entry = QueueEntry.last
    assert_equal car.id, entry.car_id
  end

  test "cannot join same queue twice while active" do
    post queue_entries_path, params: { queue_id: @queue.id }
    assert_no_difference "QueueEntry.count" do
      post queue_entries_path, params: { queue_id: @queue.id }
    end
    assert_redirected_to workshop_path(@queue.workshop)
  end

  test "cannot join non-open queue" do
    paused = service_queues(:paused_queue)
    assert_no_difference "QueueEntry.count" do
      post queue_entries_path, params: { queue_id: paused.id }
    end
    assert_response :not_found
  end

  test "create requires authentication" do
    sign_out @user
    post queue_entries_path, params: { queue_id: @queue.id }
    assert_redirected_to new_user_session_path
  end

  # --- Show ---

  test "show displays queue entry" do
    entry = queue_entries(:waiting_entry)
    sign_in users(:one)
    get queue_entry_path(entry)
    assert_response :success
  end

  test "show requires ownership" do
    entry = queue_entries(:waiting_entry)
    # @user (driver_no_workshops) is not the owner of waiting_entry (user :one)
    get queue_entry_path(entry)
    assert_response :not_found
  end

  test "show requires authentication" do
    sign_out @user
    entry = queue_entries(:waiting_entry)
    get queue_entry_path(entry)
    assert_redirected_to new_user_session_path
  end
end
