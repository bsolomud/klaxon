require "test_helper"

class QueueEntryTest < ActiveSupport::TestCase
  def setup
    @entry = queue_entries(:waiting_entry)
    @queue = service_queues(:open_queue)
  end

  test "valid queue entry" do
    assert @entry.valid?
  end

  test "requires queue" do
    @entry.service_queue = nil
    assert_not @entry.valid?
  end

  test "requires user" do
    @entry.user = nil
    assert_not @entry.valid?
  end

  test "car is optional" do
    @entry.car = nil
    assert @entry.valid?
  end

  test "requires position" do
    @entry.position = nil
    assert_not @entry.valid?
  end

  test "requires joined_at" do
    @entry.joined_at = nil
    assert_not @entry.valid?
  end

  test "defaults to waiting status" do
    entry = QueueEntry.new
    assert entry.waiting?
  end

  test "enum status values" do
    assert QueueEntry.new(status: :waiting).waiting?
    assert QueueEntry.new(status: :called).called?
    assert QueueEntry.new(status: :in_service).in_service?
    assert QueueEntry.new(status: :completed).completed?
    assert QueueEntry.new(status: :no_show).no_show?
  end

  test "position unique within queue" do
    duplicate = QueueEntry.new(
      service_queue: @queue,
      user: users(:driver_no_workshops),
      position: @entry.position,
      joined_at: Time.current
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:position], I18n.t("errors.messages.taken")
  end

  test "no duplicate active entries per user per queue" do
    duplicate = QueueEntry.new(
      service_queue: @queue,
      user: @entry.user,
      position: @queue.next_position,
      joined_at: Time.current
    )
    assert_not duplicate.valid?
  end

  test "same user can join after completing previous entry" do
    @entry.update!(status: :completed)
    new_entry = QueueEntry.new(
      service_queue: @queue,
      user: @entry.user,
      position: @queue.next_position,
      joined_at: Time.current
    )
    assert new_entry.valid?
  end

  test "active scope returns waiting, called, and in_service entries" do
    active = QueueEntry.active
    active.each do |e|
      assert_includes %w[waiting called in_service], e.status
    end
  end

  test "recompute_wait_estimates uses service category duration" do
    # open_queue has tire_service category, workshop one has tire_express WSC with 45 min duration
    entry = QueueEntry.create!(
      service_queue: @queue,
      user: users(:driver_no_workshops),
      position: @queue.next_position,
      joined_at: Time.current
    )

    # First entry (position 1) should have 0 wait
    assert_equal 0, queue_entries(:waiting_entry).reload.estimated_wait_minutes
    # Second entry (position 2) should have 45 min wait
    assert_equal 45, queue_entries(:waiting_entry_two).reload.estimated_wait_minutes
    # Third entry (position 3) should have 90 min wait
    assert_equal 90, entry.reload.estimated_wait_minutes
  end

  test "recompute_wait_estimates uses 30 min fallback when no duration set" do
    # paused_queue has car_wash category, workshop two has car_wash_basic WSC with 30 min
    queue = service_queues(:paused_queue)
    # Use a queue without matching WSC duration
    queue.update_column(:service_category_id, nil)

    entry1 = QueueEntry.create!(
      service_queue: queue,
      user: users(:one),
      position: 1,
      joined_at: Time.current
    )

    entry2 = QueueEntry.create!(
      service_queue: queue,
      user: users(:two),
      position: 2,
      joined_at: Time.current
    )

    assert_equal 0, entry1.reload.estimated_wait_minutes
    assert_equal 30, entry2.reload.estimated_wait_minutes
  end
end
