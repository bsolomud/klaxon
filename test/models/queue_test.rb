require "test_helper"

class ServiceQueueTest < ActiveSupport::TestCase
  def setup
    @queue = service_queues(:open_queue)
  end

  test "valid queue" do
    assert @queue.valid?
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
end
