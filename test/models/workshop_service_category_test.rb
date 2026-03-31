require "test_helper"

class WorkshopServiceCategoryTest < ActiveSupport::TestCase
  def setup
    @wsc = workshop_service_categories(:tire_express)
  end

  # --- Task 12: Model + validations ---

  test "valid workshop_service_category" do
    assert @wsc.valid?
  end

  test "belongs to workshop" do
    assert_equal workshops(:one), @wsc.workshop
  end

  test "belongs to service_category" do
    assert_equal service_categories(:tire_service), @wsc.service_category
  end

  test "enforces uniqueness of workshop and service_category pair" do
    duplicate = WorkshopServiceCategory.new(
      workshop: @wsc.workshop,
      service_category: @wsc.service_category,
      currency: "UAH"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:workshop_id], "has already been taken"
  end

  test "enforces uniqueness at DB level" do
    duplicate = WorkshopServiceCategory.new(
      workshop: @wsc.workshop,
      service_category: @wsc.service_category,
      currency: "UAH"
    )
    assert_raises(ActiveRecord::RecordNotUnique) do
      duplicate.save(validate: false)
    end
  end

  test "price_min must be non-negative" do
    @wsc.price_min = -1
    assert_not @wsc.valid?
    assert_includes @wsc.errors[:price_min], "must be greater than or equal to 0"
  end

  test "price_max must be non-negative" do
    @wsc.price_max = -1
    assert_not @wsc.valid?
    assert_includes @wsc.errors[:price_max], "must be greater than or equal to 0"
  end

  test "price_max must be >= price_min" do
    @wsc.price_min = 1000
    @wsc.price_max = 500
    assert_not @wsc.valid?
    assert_includes @wsc.errors[:price_max], "must be greater than or equal to minimum price"
  end

  test "estimated_duration_minutes must be positive integer" do
    @wsc.estimated_duration_minutes = 0
    assert_not @wsc.valid?

    @wsc.estimated_duration_minutes = -10
    assert_not @wsc.valid?
  end

  test "allows nil prices" do
    wsc = workshop_service_categories(:no_price)
    assert wsc.valid?
  end

  test "allows nil estimated_duration_minutes" do
    @wsc.estimated_duration_minutes = nil
    assert @wsc.valid?
  end

  test "defaults currency to UAH" do
    wsc = WorkshopServiceCategory.new(
      workshop: workshops(:two),
      service_category: service_categories(:tire_service)
    )
    assert_equal "UAH", wsc.currency
  end

  # --- Task 13: Display methods ---

  test "display_price with range" do
    assert_equal "500\u20131500 UAH / послуга", @wsc.display_price
  end

  test "display_price with equal min and max" do
    wsc = workshop_service_categories(:car_wash_basic)
    assert_equal "200 UAH / послуга", wsc.display_price
  end

  test "display_price with only min" do
    @wsc.price_max = nil
    assert_equal "from 500 UAH / послуга", @wsc.display_price
  end

  test "display_price with only max" do
    @wsc.price_min = nil
    assert_equal "up to 1500 UAH / послуга", @wsc.display_price
  end

  test "display_price with no prices" do
    wsc = workshop_service_categories(:no_price)
    assert_equal "Price on request", wsc.display_price
  end

  test "display_price with prices but no price_unit" do
    @wsc.price_unit = nil
    assert_equal "500\u20131500 UAH", @wsc.display_price
  end

  test "display_duration with minutes" do
    assert_equal "~45 min", @wsc.display_duration
  end

  test "display_duration returns nil when no duration" do
    wsc = workshop_service_categories(:no_price)
    assert_nil wsc.display_duration
  end
end
