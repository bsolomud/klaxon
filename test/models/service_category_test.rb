require "test_helper"

class ServiceCategoryTest < ActiveSupport::TestCase
  def setup
    @tire_service = service_categories(:tire_service)
    @car_wash = service_categories(:car_wash)
  end

  # Task 14 — many-to-many workshops

  test "has workshops through workshop_service_categories" do
    assert_includes @tire_service.workshops, workshops(:one)
  end

  test "workshops returns only linked workshops" do
    assert_not_includes @car_wash.workshops, workshops(:one)
  end

  test "validates presence of name" do
    category = ServiceCategory.new(slug: "test")
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "validates presence and uniqueness of slug" do
    category = ServiceCategory.new(name: "Test")
    assert_not category.valid?
    assert_includes category.errors[:slug], "can't be blank"

    duplicate = ServiceCategory.new(name: "Duplicate", slug: @tire_service.slug)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end
end
