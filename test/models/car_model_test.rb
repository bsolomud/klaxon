require "test_helper"

class CarModelTest < ActiveSupport::TestCase
  def setup
    @car_model = car_models(:camry)
  end

  test "valid car model" do
    assert @car_model.valid?
  end

  test "requires name" do
    @car_model.name = nil
    assert_not @car_model.valid?
    assert_includes @car_model.errors[:name], "can't be blank"
  end

  test "requires car_make" do
    @car_model.car_make = nil
    assert_not @car_model.valid?
  end

  test "name must be unique within same car make" do
    duplicate = CarModel.new(name: "Camry", car_make: car_makes(:toyota), status: :approved)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "same model name allowed for different makes" do
    other_make = CarMake.create!(name: "OtherMake", status: :approved)
    model = CarModel.new(name: "Camry", car_make: other_make, status: :approved)
    assert model.valid?
  end

  test "normalizes name by stripping whitespace" do
    model = CarModel.new(name: "  RAV4  ", car_make: car_makes(:toyota), status: :approved)
    assert_equal "RAV4", model.name
  end

  test "status enum values" do
    assert CarModel.new(status: :pending).pending?
    assert CarModel.new(status: :approved).approved?
    assert CarModel.new(status: :rejected).rejected?
  end

  test "approved scope returns only approved models" do
    approved = CarModel.approved
    assert_includes approved, car_models(:camry)
    assert_includes approved, car_models(:corolla)
    assert_not_includes approved, car_models(:pending_model)
  end

  test "submitted_by is optional" do
    model = CarModel.new(name: "NewModel2", car_make: car_makes(:toyota), status: :pending, submitted_by: nil)
    assert model.valid?
  end
end
