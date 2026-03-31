require "test_helper"

class WorkshopManagement::QueueEntriesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @workshop = workshops(:one)
    @queue = service_queues(:open_queue)
    @entry = queue_entries(:waiting_entry)
    sign_in @user
  end

  # --- Call ---

  test "call transitions waiting to called" do
    patch call_workshop_management_workshop_queue_queue_entry_path(@workshop, @queue, @entry),
          params: { lock_version: @entry.lock_version }
    assert_redirected_to workshop_management_workshop_queue_path(@workshop, @queue)
    assert @entry.reload.called?
    assert_not_nil @entry.called_at
  end

  test "call rejects non-waiting entry" do
    @entry.update!(status: :called, called_at: Time.current)
    patch call_workshop_management_workshop_queue_queue_entry_path(@workshop, @queue, @entry),
          params: { lock_version: @entry.lock_version }
    assert_redirected_to workshop_management_workshop_queue_path(@workshop, @queue)
    assert @entry.reload.called?
  end

  test "call handles stale object error" do
    patch call_workshop_management_workshop_queue_queue_entry_path(@workshop, @queue, @entry),
          params: { lock_version: @entry.lock_version - 1 }
    assert_redirected_to workshop_management_workshop_queue_path(@workshop, @queue)
    assert @entry.reload.waiting?
  end

  test "call recalculates wait estimates" do
    entry_two = queue_entries(:waiting_entry_two)
    patch call_workshop_management_workshop_queue_queue_entry_path(@workshop, @queue, @entry),
          params: { lock_version: @entry.lock_version }
    # After calling entry 1, entry 2 (still waiting) should get recalculated
    assert_not_nil entry_two.reload.estimated_wait_minutes
  end

  # --- Serve ---

  test "serve transitions called to in_service" do
    @entry.update!(status: :called, called_at: Time.current)
    patch serve_workshop_management_workshop_queue_queue_entry_path(@workshop, @queue, @entry),
          params: { lock_version: @entry.lock_version }
    assert_redirected_to workshop_management_workshop_queue_path(@workshop, @queue)
    assert @entry.reload.in_service?
  end

  test "serve rejects non-called entry" do
    patch serve_workshop_management_workshop_queue_queue_entry_path(@workshop, @queue, @entry),
          params: { lock_version: @entry.lock_version }
    assert_redirected_to workshop_management_workshop_queue_path(@workshop, @queue)
    assert @entry.reload.waiting?
  end

  test "serve handles stale object error" do
    @entry.update!(status: :called, called_at: Time.current)
    patch serve_workshop_management_workshop_queue_queue_entry_path(@workshop, @queue, @entry),
          params: { lock_version: @entry.lock_version - 1 }
    assert_redirected_to workshop_management_workshop_queue_path(@workshop, @queue)
    assert @entry.reload.called?
  end

  # --- Complete ---

  test "complete transitions in_service to completed" do
    @entry.update!(status: :in_service, called_at: Time.current)
    patch complete_workshop_management_workshop_queue_queue_entry_path(@workshop, @queue, @entry),
          params: { lock_version: @entry.lock_version }
    assert_redirected_to workshop_management_workshop_queue_path(@workshop, @queue)
    assert @entry.reload.completed?
  end

  test "complete rejects non-in_service entry" do
    patch complete_workshop_management_workshop_queue_queue_entry_path(@workshop, @queue, @entry),
          params: { lock_version: @entry.lock_version }
    assert_redirected_to workshop_management_workshop_queue_path(@workshop, @queue)
    assert @entry.reload.waiting?
  end

  test "complete handles stale object error" do
    @entry.update!(status: :in_service, called_at: Time.current)
    patch complete_workshop_management_workshop_queue_queue_entry_path(@workshop, @queue, @entry),
          params: { lock_version: @entry.lock_version - 1 }
    assert_redirected_to workshop_management_workshop_queue_path(@workshop, @queue)
    assert @entry.reload.in_service?
  end

  # --- No Show ---

  test "no_show transitions called to no_show" do
    @entry.update!(status: :called, called_at: Time.current)
    patch no_show_workshop_management_workshop_queue_queue_entry_path(@workshop, @queue, @entry),
          params: { lock_version: @entry.lock_version }
    assert_redirected_to workshop_management_workshop_queue_path(@workshop, @queue)
    assert @entry.reload.no_show?
  end

  test "no_show rejects non-called entry" do
    patch no_show_workshop_management_workshop_queue_queue_entry_path(@workshop, @queue, @entry),
          params: { lock_version: @entry.lock_version }
    assert_redirected_to workshop_management_workshop_queue_path(@workshop, @queue)
    assert @entry.reload.waiting?
  end

  test "no_show handles stale object error" do
    @entry.update!(status: :called, called_at: Time.current)
    patch no_show_workshop_management_workshop_queue_queue_entry_path(@workshop, @queue, @entry),
          params: { lock_version: @entry.lock_version - 1 }
    assert_redirected_to workshop_management_workshop_queue_path(@workshop, @queue)
    assert @entry.reload.called?
  end

  # --- Authorization ---

  test "requires authentication" do
    sign_out @user
    patch call_workshop_management_workshop_queue_queue_entry_path(@workshop, @queue, @entry),
          params: { lock_version: @entry.lock_version }
    assert_redirected_to new_user_session_path
  end

  test "requires workshop access" do
    sign_in users(:driver_no_workshops)
    patch call_workshop_management_workshop_queue_queue_entry_path(@workshop, @queue, @entry),
          params: { lock_version: @entry.lock_version }
    assert_response :not_found
  end
end
