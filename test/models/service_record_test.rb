require "test_helper"

class ServiceRecordTest < ActiveSupport::TestCase
  def setup
    @service_request = service_requests(:in_progress_request)
    @car = cars(:camry)
  end

  # === Validations ===

  test "valid with required attributes" do
    record = ServiceRecord.new(
      service_request: @service_request,
      summary: "Виконано діагностику",
      completed_at: Time.current
    )
    assert record.valid?
  end

  test "invalid without summary" do
    record = ServiceRecord.new(
      service_request: @service_request,
      completed_at: Time.current
    )
    assert_not record.valid?
    assert record.errors[:summary].any?
  end

  test "invalid without service_request" do
    record = ServiceRecord.new(
      summary: "Виконано діагностику",
      completed_at: Time.current
    )
    assert_not record.valid?
    assert record.errors[:service_request].any?
  end

  # === Defaults ===

  test "completed_at defaults to current time on create" do
    record = ServiceRecord.new(
      service_request: @service_request,
      summary: "Виконано діагностику"
    )
    record.validate
    assert_not_nil record.completed_at
  end

  test "completed_at can be explicitly set" do
    custom_time = 1.day.ago
    record = ServiceRecord.new(
      service_request: @service_request,
      summary: "Виконано діагностику",
      completed_at: custom_time
    )
    record.validate
    assert_in_delta custom_time, record.completed_at, 1
  end

  # === total_cost ===

  test "total_cost returns sum of labor and parts cost" do
    record = ServiceRecord.new(labor_cost: 500, parts_cost: 1200)
    assert_equal 1700, record.total_cost
  end

  test "total_cost returns zero when both costs are nil" do
    record = ServiceRecord.new
    assert_equal 0, record.total_cost
  end

  test "total_cost handles one nil cost" do
    record = ServiceRecord.new(labor_cost: 500)
    assert_equal 500, record.total_cost
  end

  # === Associations ===

  test "belongs to service_request" do
    record = service_records(:completed_record)
    assert_equal service_requests(:completed_request), record.service_request
  end

  test "has one car through service_request" do
    record = service_records(:completed_record)
    assert_equal @car, record.car
  end

  # === Uniqueness ===

  test "only one record per service request enforced at DB level" do
    record = service_records(:completed_record)
    duplicate = ServiceRecord.new(
      service_request: record.service_request,
      summary: "Дублікат",
      completed_at: Time.current
    )
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save! }
  end

  # === Odometer callback ===

  test "updates car odometer when odometer_at_service is present" do
    original_odometer = @car.odometer
    new_request = ServiceRequest.create!(
      car: @car,
      workshop: workshops(:one),
      workshop_service_category: workshop_service_categories(:tire_express),
      description: "Тест пробігу",
      preferred_time: 2.days.from_now,
      status: :in_progress
    )

    ServiceRecord.create!(
      service_request: new_request,
      summary: "Тест",
      odometer_at_service: 60000
    )

    assert_equal 60000, @car.reload.odometer
  end

  test "does not update car odometer when odometer_at_service is nil" do
    original_odometer = @car.odometer
    new_request = ServiceRequest.create!(
      car: @car,
      workshop: workshops(:one),
      workshop_service_category: workshop_service_categories(:tire_express),
      description: "Тест без пробігу",
      preferred_time: 2.days.from_now,
      status: :in_progress
    )

    ServiceRecord.create!(
      service_request: new_request,
      summary: "Тест"
    )

    assert_equal original_odometer, @car.reload.odometer
  end
end
