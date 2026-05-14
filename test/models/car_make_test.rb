require "test_helper"

class CarMakeTest < ActiveSupport::TestCase
  def setup
    @car_make = car_makes(:toyota)
  end

  test "valid car make" do
    assert @car_make.valid?
  end

  test "requires name" do
    @car_make.name = nil
    assert_not @car_make.valid?
    assert_includes @car_make.errors[:name], "can't be blank"
  end

  test "name must be unique case-insensitively" do
    duplicate = CarMake.new(name: "toyota", status: :approved)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "normalizes name by stripping whitespace" do
    car_make = CarMake.new(name: "  Honda  ", status: :approved)
    assert_equal "Honda", car_make.name
  end

  test "status enum values" do
    assert CarMake.new(status: :pending).pending?
    assert CarMake.new(status: :approved).approved?
    assert CarMake.new(status: :rejected).rejected?
  end

  test "approved scope returns only approved makes" do
    approved = CarMake.approved
    assert_includes approved, car_makes(:toyota)
    assert_not_includes approved, car_makes(:pending_make)
    assert_not_includes approved, car_makes(:rejected_make)
  end

  test "has many car models" do
    assert_respond_to @car_make, :car_models
    assert_includes @car_make.car_models, car_models(:camry)
  end

  test "destroying make destroys models" do
    make = CarMake.create!(name: "TestMake", status: :approved)
    make.car_models.create!(name: "TestModel", status: :approved)
    assert_difference "CarModel.count", -1 do
      make.destroy
    end
  end

  test "submitted_by is optional" do
    car_make = CarMake.new(name: "NewMake", status: :pending, submitted_by: nil)
    assert car_make.valid?
  end
end
