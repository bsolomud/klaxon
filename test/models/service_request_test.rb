require "test_helper"

class ServiceRequestTest < ActiveSupport::TestCase
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
end
