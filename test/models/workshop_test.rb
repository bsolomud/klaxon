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

  # Task 107 — sorted_by_distance scope

  test "sorted_by_distance orders by proximity" do
    # Workshop :one is at 50.4501, 30.5234
    # Workshop :two is at 50.4628, 30.5179
    # Point near workshop :two
    results = Workshop.sorted_by_distance(50.4630, 30.5180)
    one_idx = results.index(workshops(:one))
    two_idx = results.index(workshops(:two))
    assert two_idx < one_idx, "closer workshop should come first"
  end

  test "sorted_by_distance puts workshops without coordinates last" do
    workshops(:pending_workshop).update_columns(latitude: nil, longitude: nil)
    results = Workshop.sorted_by_distance(50.45, 30.52)
    last_with_coords = results.select { |w| w.latitude.present? }.last
    first_without = results.detect { |w| w.latitude.nil? }
    assert results.index(last_with_coords) < results.index(first_without) if first_without
  end

  # Task 97 — cached rating fields

  test "review_count defaults to 0" do
    workshop = Workshop.create!(name: "Тест", phone: "+380500000000", address: "вул. Тестова, 1", city: "Київ", country: "UA")
    assert_equal 0, workshop.review_count
  end

  test "recompute_rating! updates avg_rating and review_count" do
    workshop = workshops(:one)
    workshop.recompute_rating!
    workshop.reload

    published = workshop.reviews.published
    expected_count = published.count
    expected_avg = published.average(:rating)&.round(2)

    assert_equal expected_count, workshop.review_count
    assert_equal expected_avg, workshop.avg_rating
  end

  test "creating a review updates cached rating" do
    workshop = workshops(:two)
    # hidden_review exists for workshop :two but is hidden
    assert_equal 0, workshop.review_count

    completed = service_requests(:other_user_completed)
    # Remove the hidden review to free up the service_request
    reviews(:hidden_review).destroy!

    Review.create!(
      user: users(:two),
      workshop: workshop,
      service_request: completed,
      rating: 4
    )
    workshop.reload

    assert_equal 1, workshop.review_count
    assert_equal BigDecimal("4.0"), workshop.avg_rating
  end

  test "hiding a review excludes it from aggregate" do
    workshop = workshops(:one)
    review = reviews(:published_review)

    assert_equal 1, workshop.reviews.published.count

    review.update!(status: :hidden)
    workshop.reload

    assert_equal 0, workshop.review_count
    assert_nil workshop.avg_rating
  end

  # Task 105 — text_search scope

  test "text_search returns matches by name" do
    results = Workshop.text_search("Експрес")
    assert_includes results, workshops(:one)
    assert_not_includes results, workshops(:two)
  end

  test "text_search returns matches by address" do
    results = Workshop.text_search("Хрещатик")
    assert_includes results, workshops(:one)
    assert_not_includes results, workshops(:two)
  end

  test "text_search is case-insensitive" do
    results = Workshop.text_search("експрес")
    assert_includes results, workshops(:one)
  end

  test "text_search returns all when query is blank" do
    assert_equal Workshop.all.count, Workshop.text_search("").count
    assert_equal Workshop.all.count, Workshop.text_search(nil).count
  end
end
