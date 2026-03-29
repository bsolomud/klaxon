require "test_helper"

class WorkshopTest < ActiveSupport::TestCase
  def setup
    @workshop = workshops(:one)
  end

  test "has operators through workshop_operators" do
    assert_includes @workshop.operators, users(:one)
    assert_includes @workshop.operators, users(:two)
  end

  test "operators returns only users linked via workshop_operators" do
    assert_not_includes @workshop.operators, User.create!(
      email: "unlinked@example.com",
      password: "password"
    )
  end

  test "destroying workshop destroys workshop_operators" do
    workshop = workshops(:pending_workshop)
    assert_difference "WorkshopOperator.count", -1 do
      workshop.destroy
    end
  end

  # Task 10 — status enum

  test "defaults to pending status" do
    workshop = Workshop.new
    assert workshop.pending?
  end

  test "active scope returns only active workshops" do
    active_workshops = Workshop.active
    assert_includes active_workshops, workshops(:one)
    assert_includes active_workshops, workshops(:two)
    assert_not_includes active_workshops, workshops(:pending_workshop)
  end

  test "status transitions work" do
    workshop = workshops(:pending_workshop)
    assert workshop.pending?

    workshop.active!
    assert workshop.active?

    workshop.suspended!
    assert workshop.suspended?
  end

  test "can transition to declined with decline_reason" do
    workshop = workshops(:pending_workshop)
    workshop.declined!
    workshop.update!(decline_reason: "Не відповідає вимогам")

    assert workshop.declined?
    assert_equal "Не відповідає вимогам", workshop.decline_reason
  end

  test "decline_reason is nullable" do
    assert_nil @workshop.decline_reason
  end

  # Task 14 — many-to-many service categories

  test "has service_categories through workshop_service_categories" do
    assert_includes @workshop.service_categories, service_categories(:tire_service)
  end

  test "service_categories returns only linked categories" do
    assert_not_includes @workshop.service_categories, service_categories(:car_wash)
  end

  test "destroying workshop destroys workshop_service_categories" do
    workshop = workshops(:pending_workshop)
    assert_difference "WorkshopServiceCategory.count", -1 do
      workshop.destroy
    end
  end

  # Task 19 — by_category_slug uses join table

  test "by_category_slug returns workshops with matching service category" do
    results = Workshop.by_category_slug("tire-service")
    assert_includes results, workshops(:one)
    assert_not_includes results, workshops(:two)
  end

  test "by_category_slug returns empty when no match" do
    assert_empty Workshop.by_category_slug("nonexistent-slug")
  end

  test "by_category_slug works with chained scopes" do
    results = Workshop.active.by_category_slug("tire-service")
    assert_includes results, workshops(:one)
    assert_not_includes results, workshops(:pending_workshop)
  end

  # Task 27 — geocoordinates columns

  test "latitude and longitude accept decimal values" do
    @workshop.update!(latitude: 50.450100, longitude: 30.523400)
    @workshop.reload
    assert_equal BigDecimal("50.4501000"), @workshop.latitude
    assert_equal BigDecimal("30.5234000"), @workshop.longitude
  end

  test "latitude and longitude are nullable" do
    @workshop.update!(latitude: nil, longitude: nil)
    @workshop.reload
    assert_nil @workshop.latitude
    assert_nil @workshop.longitude
  end

  # Task 28 — geocoding

  test "full_address combines address, city, and country" do
    assert_equal "вул. Хрещатик, 1, Київ, UA", @workshop.full_address
  end

  test "geocodes on create when address is present" do
    workshop = Workshop.create!(
      name: "Тест Майстерня",
      phone: "+380501111111",
      address: "вул. Велика Васильківська, 100",
      city: "Київ",
      country: "UA"
    )
    assert_equal BigDecimal("50.4501"), workshop.latitude
    assert_equal BigDecimal("30.5234"), workshop.longitude
  end

  test "geocodes when address changes" do
    Geocoder::Lookup::Test.add_stub(
      "вул. Нова, 5, Львів, UA",
      [{ "latitude" => 49.8397, "longitude" => 24.0297 }]
    )
    @workshop.update!(address: "вул. Нова, 5", city: "Львів")
    assert_equal BigDecimal("49.8397"), @workshop.latitude
    assert_equal BigDecimal("24.0297"), @workshop.longitude
  end

  test "does not geocode when non-address fields change" do
    @workshop.update_columns(latitude: 48.0, longitude: 25.0)
    @workshop.reload
    @workshop.update!(name: "Нова Назва")
    assert_equal BigDecimal("48.0"), @workshop.latitude
    assert_equal BigDecimal("25.0"), @workshop.longitude
  end

  # Task 29 — near_location scope

  test "near_location returns workshops within bounding box" do
    results = Workshop.near_location(50.45, 30.52)
    assert_includes results, workshops(:one)
    assert_includes results, workshops(:two)
  end

  test "near_location excludes workshops outside radius" do
    results = Workshop.near_location(48.0, 24.0, 5)
    assert_not_includes results, workshops(:one)
    assert_not_includes results, workshops(:two)
  end

  test "near_location with small radius narrows results" do
    results = Workshop.near_location(50.4501, 30.5234, 1)
    assert_includes results, workshops(:one)
  end
end
