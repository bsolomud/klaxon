require "test_helper"

class QueueServiceRecorderTest < ActiveSupport::TestCase
  def setup
    # open_queue -> workshop one (has tire_express WSC), car camry
    @entry = queue_entries(:waiting_entry)
  end

  test "records a completed service request + record for a queue visit" do
    assert_difference ["ServiceRequest.count", "ServiceRecord.count"], 1 do
      QueueServiceRecorder.new(@entry).call
    end
    request = @entry.reload.service_request
    assert request.completed?
    assert_equal @entry.car, request.car
    assert_equal workshops(:one), request.workshop
    assert request.service_record.present?
    # completed -> reviewable
    assert Review.new(service_request: request, user: request.car.user, workshop: request.workshop, rating: 5).valid?
  end

  test "is idempotent" do
    QueueServiceRecorder.new(@entry).call
    assert_no_difference "ServiceRequest.count" do
      QueueServiceRecorder.new(@entry).call
    end
  end

  test "no-op without a car" do
    @entry.update!(car: nil)
    assert_no_difference "ServiceRequest.count" do
      QueueServiceRecorder.new(@entry).call
    end
  end

  test "no-op when the queue has no service category" do
    @entry.service_queue.update_column(:service_category_id, nil) # rubocop:disable Rails/SkipsModelValidations
    assert_no_difference "ServiceRequest.count" do
      QueueServiceRecorder.new(@entry).call
    end
  end
end
