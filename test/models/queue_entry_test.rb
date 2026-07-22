require "test_helper"

class QueueEntryTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

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
    assert_includes duplicate.errors.details[:position].map { |e| e[:error] }, :taken
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

  test "cancelled entries are excluded from active" do
    @entry.cancelled!
    assert_not_includes QueueEntry.active, @entry
  end

  test "waiting entry waits a full slot when the only bay is busy" do
    # open_queue: 1 bay, tire_service duration 45. Put entry 1 into service;
    # entry 2 is then first-in-line but must wait for the busy bay to clear.
    queue_entries(:waiting_entry).update!(status: :in_service)
    assert_equal 45, queue_entries(:waiting_entry_two).reload.estimated_wait_minutes
  end

  test "leaving the queue recomputes remaining estimates" do
    queue_entries(:waiting_entry).destroy!
    assert_equal 0, queue_entries(:waiting_entry_two).reload.estimated_wait_minutes
  end

  test "estimates account for multiple bays" do
    @queue.update!(concurrency: 2)
    queue_entries(:waiting_entry).recompute_wait_estimates
    assert_equal 0, queue_entries(:waiting_entry).reload.estimated_wait_minutes
    assert_equal 0, queue_entries(:waiting_entry_two).reload.estimated_wait_minutes
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
    queue.update_column(:service_category_id, nil) # rubocop:disable Rails/SkipsModelValidations

    # The global one-active-entry-per-user index means users :one and :two
    # cannot hold their fixture entries and these new ones at the same time.
    QueueEntry.delete_all

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

  test "broadcasts append on create" do
    assert_broadcasts("queue_#{@queue.id}_drivers", 1) do
      assert_broadcasts("queue_#{@queue.id}_operators", 1) do
        QueueEntry.create!(
          service_queue: @queue,
          user: users(:driver_no_workshops),
          position: @queue.next_position,
          joined_at: Time.current
        )
      end
    end
  end

  test "broadcasts replace on status change" do
    # 1 for the entry itself + 1 for sibling wait estimate update
    assert_broadcasts("queue_#{@queue.id}_drivers", 2) do
      assert_broadcasts("queue_#{@queue.id}_operators", 2) do
        @entry.update!(status: :called)
      end
    end
  end

  test "does not broadcast on non-status update" do
    assert_no_broadcasts("queue_#{@queue.id}_drivers") do
      assert_no_broadcasts("queue_#{@queue.id}_operators") do
        @entry.update!(estimated_wait_minutes: 99)
      end
    end
  end

  test "broadcasts remove and sibling estimate refresh on destroy" do
    # 1 removal + 1 sibling estimate refresh (remaining drivers move up)
    assert_broadcasts("queue_#{@queue.id}_drivers", 2) do
      assert_broadcasts("queue_#{@queue.id}_operators", 2) do
        @entry.destroy!
      end
    end
  end

  test "user cannot be active in two different queues" do
    QueueEntry.create!(
      service_queue: @queue,
      user: users(:driver_no_workshops),
      position: @queue.next_position,
      joined_at: Time.current
    )
    other = QueueEntry.new(
      service_queue: service_queues(:paused_queue),
      user: users(:driver_no_workshops),
      position: 1,
      joined_at: Time.current
    )
    assert_not other.valid?
  end

  test "user can join again after leaving (destroying) previous entry" do
    first = QueueEntry.create!(
      service_queue: @queue,
      user: users(:driver_no_workshops),
      position: @queue.next_position,
      joined_at: Time.current
    )
    first.destroy!
    second = QueueEntry.new(
      service_queue: service_queues(:paused_queue),
      user: users(:driver_no_workshops),
      position: 1,
      joined_at: Time.current
    )
    assert second.valid?
  end
end
