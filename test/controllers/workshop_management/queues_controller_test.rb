require "test_helper"

class WorkshopManagement::QueuesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @workshop = workshops(:one)
    @queue = service_queues(:open_queue)
    sign_in @user
  end

  # --- Index ---

  test "index shows today's queues" do
    get workshop_management_workshop_queues_path(@workshop)
    assert_response :success
  end

  test "index scoped to current workshop" do
    get workshop_management_workshop_queues_path(@workshop)
    assert_response :success
  end

  test "index requires authentication" do
    sign_out @user
    get workshop_management_workshop_queues_path(@workshop)
    assert_redirected_to new_user_session_path
  end

  test "index requires workshop access" do
    sign_in users(:driver_no_workshops)
    get workshop_management_workshop_queues_path(@workshop)
    assert_response :not_found
  end

  # --- Show ---

  test "show displays queue with entries" do
    get workshop_management_workshop_queue_path(@workshop, @queue)
    assert_response :success
  end

  test "show requires workshop access" do
    sign_in users(:driver_no_workshops)
    get workshop_management_workshop_queue_path(@workshop, @queue)
    assert_response :not_found
  end

  # --- Open ---

  test "open reopens a paused queue" do
    @queue.update!(status: :paused)

    patch open_workshop_management_workshop_queues_path(@workshop),
          params: { service_category_id: @queue.service_category_id }
    assert_redirected_to workshop_management_workshop_queue_path(@workshop, @queue)
    assert @queue.reload.open?
  end

  test "open creates a new queue when none exists" do
    category = @queue.service_category
    @queue.destroy!

    assert_difference "ServiceQueue.count", 1 do
      patch open_workshop_management_workshop_queues_path(@workshop),
            params: { service_category_id: category.id }
    end

    new_queue = ServiceQueue.last
    assert new_queue.open?
    assert_equal Date.current, new_queue.date
    assert_redirected_to workshop_management_workshop_queue_path(@workshop, new_queue)
  end

  # --- Pause ---

  test "pause pauses an open queue" do
    patch pause_workshop_management_workshop_queue_path(@workshop, @queue)
    assert_redirected_to workshop_management_workshop_queue_path(@workshop, @queue)
    assert @queue.reload.paused?
  end

  test "pause rejects non-open queue" do
    @queue.update!(status: :closed)
    patch pause_workshop_management_workshop_queue_path(@workshop, @queue)
    assert_redirected_to workshop_management_workshop_queue_path(@workshop, @queue)
    assert @queue.reload.closed?
  end

  # --- Close ---

  test "close closes an open queue" do
    patch close_workshop_management_workshop_queue_path(@workshop, @queue)
    assert_redirected_to workshop_management_workshop_queue_path(@workshop, @queue)
    assert @queue.reload.closed?
  end

  test "close closes a paused queue" do
    @queue.update!(status: :paused)
    patch close_workshop_management_workshop_queue_path(@workshop, @queue)
    assert_redirected_to workshop_management_workshop_queue_path(@workshop, @queue)
    assert @queue.reload.closed?
  end

  test "close rejects already closed queue" do
    @queue.update!(status: :closed)
    patch close_workshop_management_workshop_queue_path(@workshop, @queue)
    assert_redirected_to workshop_management_workshop_queue_path(@workshop, @queue)
  end
end
