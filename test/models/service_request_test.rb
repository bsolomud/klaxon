require "test_helper"

class ServiceRequestTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  def setup
    @user = users(:one)
    @car = cars(:camry)
    @workshop = workshops(:one)
    @wsc = workshop_service_categories(:tire_express)
    @request = service_requests(:pending_request)
  end

  test "valid service request" do
    assert @request.valid?
  end

  test "defaults to pending status" do
    sr = ServiceRequest.new(
      car: @car,
      workshop: @workshop,
      workshop_service_category: @wsc,
      description: "Test",
      preferred_time: 1.day.from_now
    )
    assert_equal "pending", sr.status
  end

  test "requires description" do
    @request.description = nil
    assert_not @request.valid?
    assert_includes @request.errors[:description], I18n.t("activerecord.errors.messages.blank")
  end

  test "requires preferred_time" do
    @request.preferred_time = nil
    assert_not @request.valid?
    assert_includes @request.errors[:preferred_time], I18n.t("activerecord.errors.messages.blank")
  end

  test "has lock_version for optimistic locking" do
    assert_equal 0, @request.lock_version
  end

  test "enum status values" do
    expected = { "pending" => 0, "accepted" => 1, "rejected" => 2, "in_progress" => 3, "completed" => 4 }
    assert_equal expected, ServiceRequest.statuses
  end

  # Task 52: Price snapshot

  test "snapshot_price populates price_snapshot on create" do
    sr = ServiceRequest.create!(
      car: @car,
      workshop: @workshop,
      workshop_service_category: @wsc,
      description: "Test snapshot",
      preferred_time: 1.day.from_now
    )

    assert_equal @wsc.price_min.to_f, sr.price_snapshot["min"].to_f
    assert_equal @wsc.price_max.to_f, sr.price_snapshot["max"].to_f
    assert_equal @wsc.currency, sr.price_snapshot["currency"]
    assert_equal @wsc.price_unit, sr.price_snapshot["unit"]
  end

  test "display_price reads the snapshot on an unsaved record (string keys)" do
    sr = ServiceRequest.new(
      car: @car,
      workshop: @workshop,
      workshop_service_category: @wsc,
      description: "Test",
      preferred_time: 1.day.from_now
    )
    sr.send(:snapshot_price)

    # String keys must match what display_price reads, even before the record
    # is persisted and reloaded from jsonb.
    assert_equal @wsc.price_min.to_f, sr.price_snapshot["min"].to_f
    assert_includes sr.display_price, @wsc.price_min.to_i.to_s
    assert_not_equal I18n.t("service_requests.price_on_request"), sr.display_price
  end

  test "changing WSC pricing after creation does not affect existing requests" do
    sr = ServiceRequest.create!(
      car: @car,
      workshop: @workshop,
      workshop_service_category: @wsc,
      description: "Test immutability",
      preferred_time: 1.day.from_now
    )

    original_min = sr.price_snapshot["min"].to_f

    @wsc.update!(price_min: 9999, price_max: 9999)

    sr.reload
    assert_equal original_min, sr.price_snapshot["min"].to_f
  end

  # Task 53: Custom validations

  test "cannot create request for service not offered by workshop" do
    other_wsc = workshop_service_categories(:car_wash_basic) # belongs to workshop :two
    sr = ServiceRequest.new(
      car: @car,
      workshop: @workshop,
      workshop_service_category: other_wsc,
      description: "Mismatch",
      preferred_time: 1.day.from_now
    )

    assert_not sr.valid?
    assert sr.errors[:workshop_service_category].any?
  end

  # Rule 8: preferred_time within working hours

  test "valid when preferred_time falls within working hours" do
    day = 1.day.from_now.wday
    @workshop.working_hours.create!(day_of_week: day, opens_at: "08:00", closes_at: "18:00")
    @request.preferred_time = 1.day.from_now.change(hour: 10)
    assert @request.valid?
  end

  test "invalid when preferred_time is outside working hours" do
    day = 1.day.from_now.wday
    @workshop.working_hours.create!(day_of_week: day, opens_at: "08:00", closes_at: "18:00")
    @request.preferred_time = 1.day.from_now.change(hour: 20)
    assert_not @request.valid?
    assert @request.errors[:preferred_time].any?
  end

  test "invalid when preferred_time is on a day the workshop is closed" do
    day = 1.day.from_now.wday
    @workshop.working_hours.create!(day_of_week: day, closed: true)
    @request.preferred_time = 1.day.from_now.change(hour: 10)
    assert_not @request.valid?
    assert @request.errors[:preferred_time].any?
  end

  test "valid when the workshop has no hours configured for that day" do
    # No working_hours records exist for this workshop, so there is nothing to
    # validate preferred_time against — the request is allowed.
    @request.preferred_time = 1.day.from_now.change(hour: 3)
    assert @request.valid?
  end

  test "invalid when preferred_time is in the past on create" do
    sr = ServiceRequest.new(
      car: @car,
      workshop: @workshop,
      workshop_service_category: @wsc,
      description: "Past time",
      preferred_time: 1.day.ago
    )
    assert_not sr.valid?
    assert sr.errors[:preferred_time].any?
  end

  test "display_price with min and max" do
    assert_equal "500\u20131500 UAH", @request.display_price
  end

  test "display_price with equal min and max" do
    @request.price_snapshot = { "min" => 200, "max" => 200, "currency" => "UAH" }
    assert_equal "200 UAH", @request.display_price
  end

  test "display_price with blank snapshot" do
    @request.price_snapshot = nil
    assert_equal I18n.t("service_requests.price_on_request"), @request.display_price
  end

  test "recent scope orders by created_at desc" do
    assert_equal ServiceRequest.order(created_at: :desc).to_a, ServiceRequest.recent.to_a
  end

  test "broadcasts to user and workshop streams on status change" do
    assert_broadcasts("user_#{@request.car.user_id}_requests", 1) do
      assert_broadcasts("workshop_#{@request.workshop_id}_requests", 1) do
        @request.update!(status: :accepted)
      end
    end
  end

  test "does not broadcast on non-status update" do
    assert_no_broadcasts("user_#{@request.car.user_id}_requests") do
      assert_no_broadcasts("workshop_#{@request.workshop_id}_requests") do
        @request.update!(description: "Updated description")
      end
    end
  end
end
