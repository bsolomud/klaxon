require "test_helper"

class CarTest < ActiveSupport::TestCase
  def setup
    @car = cars(:camry)
  end

  # --- Enums ---

  test "fuel_type enum has correct values" do
    assert Car.fuel_types.key?("gasoline")
    assert Car.fuel_types.key?("diesel")
    assert Car.fuel_types.key?("electric")
    assert Car.fuel_types.key?("hybrid")
    assert_equal 0, Car.fuel_types["gasoline"]
    assert_equal 1, Car.fuel_types["diesel"]
    assert_equal 2, Car.fuel_types["electric"]
    assert_equal 3, Car.fuel_types["hybrid"]
  end

  test "transmission enum has correct values" do
    assert Car.transmissions.key?("manual")
    assert Car.transmissions.key?("automatic")
    assert_equal 0, Car.transmissions["manual"]
    assert_equal 1, Car.transmissions["automatic"]
  end

  # --- Validations ---

  test "valid car passes validation" do
    assert @car.valid?
  end

  test "make is required" do
    @car.make = nil
    assert_not @car.valid?
    assert_includes @car.errors[:make], I18n.t("activerecord.errors.messages.blank")
  end

  test "model is required" do
    @car.model = nil
    assert_not @car.valid?
    assert_includes @car.errors[:model], I18n.t("activerecord.errors.messages.blank")
  end

  test "year is required" do
    @car.year = nil
    assert_not @car.valid?
    assert_includes @car.errors[:year], I18n.t("activerecord.errors.messages.blank")
  end

  test "year must be greater than 1885" do
    @car.year = 1885
    assert_not @car.valid?
    assert @car.errors[:year].any?
  end

  test "year 1886 is valid" do
    @car.year = 1886
    assert @car.valid?
  end

  test "license_plate is required" do
    @car.license_plate = nil
    assert_not @car.valid?
    assert_includes @car.errors[:license_plate], I18n.t("activerecord.errors.messages.blank")
  end

  test "fuel_type is required" do
    @car.fuel_type = nil
    assert_not @car.valid?
  end

  test "license_plate is unique case-insensitively" do
    duplicate = Car.new(
      user: users(:two),
      make: "Test",
      model: "Car",
      year: 2020,
      license_plate: @car.license_plate.downcase,
      fuel_type: :gasoline
    )
    assert_not duplicate.valid?
    assert duplicate.errors[:license_plate].any?
  end

  test "license_plate is normalized to uppercase" do
    car = Car.new(license_plate: " aa1234bb ")
    car.valid?
    assert_equal "AA1234BB", car.license_plate
  end

  test "VIN must be exactly 17 characters" do
    @car.vin = "SHORT"
    assert_not @car.valid?
    assert @car.errors[:vin].any?
  end

  test "VIN of 17 characters is valid" do
    @car.vin = "1HGBH41JXMN109186"
    assert @car.valid?
  end

  test "VIN is optional (nil allowed)" do
    car = cars(:civic)
    assert_nil car.vin
    assert car.valid?
  end

  test "VIN uniqueness is enforced" do
    duplicate = Car.new(
      user: users(:two),
      make: "Test",
      model: "Car",
      year: 2020,
      license_plate: "ZZ9999ZZ",
      fuel_type: :gasoline,
      vin: @car.vin
    )
    assert_not duplicate.valid?
    assert duplicate.errors[:vin].any?
  end

  test "VIN is normalized to uppercase" do
    car = Car.new(vin: "1hgbh41jxmn109186")
    car.valid?
    assert_equal "1HGBH41JXMN109186", car.vin
  end

  test "blank VIN is normalized to nil" do
    car = Car.new(vin: "  ")
    car.valid?
    assert_nil car.vin
  end

  test "engine_volume must be nil when electric" do
    car = cars(:leaf)
    assert car.electric?
    car.engine_volume = 2.0
    assert_not car.valid?
    assert car.errors[:engine_volume].any?
  end

  test "engine_volume nil is valid for electric" do
    car = cars(:leaf)
    assert_nil car.engine_volume
    assert car.valid?
  end

  # --- display_name ---

  test "display_name returns year make model" do
    assert_equal "2020 Toyota Camry", @car.display_name
  end

  # --- Associations ---

  test "belongs to user" do
    assert_equal users(:one), @car.user
  end

  # --- CarOwnershipRecord on create (Task 46) ---

  test "creating a car auto-creates ownership record" do
    car = Car.create!(
      user: users(:two),
      make: "Test", model: "Auto", year: 2024,
      license_plate: "ZZ0000AA", fuel_type: :gasoline
    )
    assert_equal 1, car.car_ownership_records.count
    record = car.car_ownership_records.first
    assert_equal users(:two), record.user
    assert_nil record.ended_at
    assert_nil record.car_transfer_id
    assert_not_nil record.started_at
  end
end
