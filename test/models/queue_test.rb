require "test_helper"

class ServiceQueueTest < ActiveSupport::TestCase
  def setup
    @queue = service_queues(:open_queue)
  end

  test "valid queue" do
    assert @queue.valid?
  end

  test "concurrency defaults to 1" do
    assert_equal 1, ServiceQueue.new.concurrency
  end

  test "serving_count counts in-service entries" do
    assert_equal 0, @queue.serving_count
    queue_entries(:waiting_entry).update!(status: :in_service)
    assert_equal 1, @queue.serving_count
  end

  test "requires workshop" do
    @queue.workshop = nil
    assert_not @queue.valid?
  end

  test "requires date" do
    @queue.date = nil
    assert_not @queue.valid?
  end

  test "service_category is optional" do
    @queue.service_category = nil
    assert @queue.valid?
  end

  test "defaults to open status" do
    queue = ServiceQueue.new
    assert queue.open?
  end

  test "enum status values" do
    assert ServiceQueue.new(status: :open).open?
    assert ServiceQueue.new(status: :paused).paused?
    assert ServiceQueue.new(status: :closed).closed?
  end

  test "composite unique index on workshop, service_category, date" do
    duplicate = ServiceQueue.new(
      workshop: @queue.workshop,
      service_category: @queue.service_category,
      date: @queue.date
    )
    assert_not duplicate.valid?
  end

  test "today scope returns only today's queues" do
    today_queues = ServiceQueue.today
    today_queues.each do |q|
      assert_equal Date.current, q.date
    end
  end

  test "next_position returns 1 for empty queue" do
    queue = service_queues(:closed_queue)
    queue.queue_entries.destroy_all
    assert_equal 1, queue.next_position
  end

  test "next_position returns max position + 1" do
    assert_equal (@queue.queue_entries.maximum(:position) || 0) + 1, @queue.next_position
  end

  test "waiting_count counts only waiting entries" do
    # open_queue fixture has two waiting entries
    assert_equal 2, @queue.waiting_count
  end

  test "entry_duration_minutes uses the workshop's service-category duration" do
    # workshop one offers tire_service via WSC tire_express (45 min)
    assert_equal 45, @queue.entry_duration_minutes
  end

  test "entry_duration_minutes falls back to 30 without a category" do
    @queue.update_column(:service_category_id, nil) # rubocop:disable Rails/SkipsModelValidations
    assert_equal 30, @queue.entry_duration_minutes
  end

  test "prospective_wait_minutes is waiting_count times duration" do
    assert_equal 90, @queue.prospective_wait_minutes
  end
end
