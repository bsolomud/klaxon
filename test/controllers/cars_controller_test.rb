require "test_helper"

class CarsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @car = cars(:camry)
    sign_in @user
  end

  # --- Index ---

  test "index returns success" do
    get cars_path
    assert_response :success
  end

  test "index shows only current user's cars" do
    get cars_path
    assert_response :success
    assert_select "h2", text: cars(:camry).display_name
    assert_select "h2", text: cars(:civic).display_name
    assert_select "h2", text: cars(:other_user_car).display_name, count: 0
  end

  test "index requires authentication" do
    sign_out @user
    get cars_path
    assert_redirected_to new_user_session_path
  end

  test "index shows add car link" do
    get cars_path
    assert_select "a[href=?]", new_car_path
  end

  # --- Show ---

  test "show returns success for own car" do
    get car_path(@car)
    assert_response :success
    assert_select "h1", text: @car.display_name
  end

  test "show displays car details" do
    get car_path(@car)
    assert_response :success
    assert_select "dd", text: @car.make
    assert_select "dd", text: @car.model
    assert_select "dd", text: @car.year.to_s
  end

  test "show displays VIN when present" do
    get car_path(@car)
    assert_response :success
    assert_select "dd", text: @car.vin
  end

  test "cannot view another user's car" do
    other_car = cars(:other_user_car)
    get car_path(other_car)
    assert_response :not_found
  end

  test "show requires authentication" do
    sign_out @user
    get car_path(@car)
    assert_redirected_to new_user_session_path
  end

  # --- New ---

  test "new returns success" do
    get new_car_path
    assert_response :success
  end

  test "new renders form" do
    get new_car_path
    assert_select "form[action=?]", cars_path
  end

  test "new requires authentication" do
    sign_out @user
    get new_car_path
    assert_redirected_to new_user_session_path
  end

  # --- Create ---

  test "create adds a car for current user" do
    assert_difference "Car.count", 1 do
      post cars_path, params: { car: {
        make: "Ford", model: "Focus", year: 2021,
        license_plate: "XX9999YY", fuel_type: "gasoline"
      } }
    end

    car = Car.last
    assert_equal @user.id, car.user_id
    assert_equal "Ford", car.make
    assert_redirected_to car_path(car)
    assert_equal I18n.t("cars.create.success"), flash[:notice]
  end

  test "create with valid VIN succeeds" do
    assert_difference "Car.count", 1 do
      post cars_path, params: { car: {
        make: "Ford", model: "Focus", year: 2021,
        license_plate: "XX8888YY", fuel_type: "gasoline",
        vin: "WBA3A5C51CF256789"
      } }
    end
  end

  test "create re-renders form on validation error" do
    assert_no_difference "Car.count" do
      post cars_path, params: { car: {
        make: "", model: "", year: nil,
        license_plate: "", fuel_type: "gasoline"
      } }
    end
    assert_response :unprocessable_entity
  end

  test "create requires authentication" do
    sign_out @user
    post cars_path, params: { car: {
      make: "Ford", model: "Focus", year: 2021,
      license_plate: "XX9999YY", fuel_type: "gasoline"
    } }
    assert_redirected_to new_user_session_path
  end

  # --- Edit ---

  test "edit returns success for own car" do
    get edit_car_path(@car)
    assert_response :success
  end

  test "edit renders form with car data" do
    get edit_car_path(@car)
    assert_select "form[action=?]", car_path(@car)
  end

  test "cannot edit another user's car" do
    other_car = cars(:other_user_car)
    get edit_car_path(other_car)
    assert_response :not_found
  end

  test "edit requires authentication" do
    sign_out @user
    get edit_car_path(@car)
    assert_redirected_to new_user_session_path
  end

  # --- Update ---

  test "update changes car attributes" do
    patch car_path(@car), params: { car: { make: "Toyota Updated" } }
    assert_redirected_to car_path(@car)
    assert_equal "Toyota Updated", @car.reload.make
    assert_equal I18n.t("cars.update.success"), flash[:notice]
  end

  test "update re-renders form on validation error" do
    patch car_path(@car), params: { car: { make: "" } }
    assert_response :unprocessable_entity
  end

  test "cannot update another user's car" do
    other_car = cars(:other_user_car)
    patch car_path(other_car), params: { car: { make: "Hacked" } }
    assert_response :not_found
    assert_equal "BMW", other_car.reload.make
  end

  test "update requires authentication" do
    sign_out @user
    patch car_path(@car), params: { car: { make: "X" } }
    assert_redirected_to new_user_session_path
  end

  # --- Destroy ---

  test "destroy removes car" do
    assert_difference "Car.count", -1 do
      delete car_path(@car)
    end
    assert_redirected_to cars_path
    assert_equal I18n.t("cars.destroy.success"), flash[:notice]
  end

  test "cannot destroy another user's car" do
    other_car = cars(:other_user_car)
    assert_no_difference "Car.count" do
      delete car_path(other_car)
    end
    assert_response :not_found
  end

  test "destroy requires authentication" do
    sign_out @user
    assert_no_difference "Car.count" do
      delete car_path(@car)
    end
    assert_redirected_to new_user_session_path
  end

  # --- VIN duplicate detection (Task 42) ---

  test "create blocks duplicate VIN belonging to another user" do
    existing_vin = cars(:leaf).vin
    assert_not_nil existing_vin

    assert_no_difference "Car.count" do
      post cars_path, params: { car: {
        make: "Nissan", model: "Leaf Copy", year: 2023,
        license_plate: "ZZ1111AA", fuel_type: "electric",
        vin: existing_vin
      } }
    end
    assert_response :unprocessable_entity
  end

  test "create shows VIN duplicate warning for another user's VIN" do
    existing_vin = cars(:leaf).vin

    post cars_path, params: { car: {
      make: "Nissan", model: "Leaf Copy", year: 2023,
      license_plate: "ZZ1111AA", fuel_type: "electric",
      vin: existing_vin
    } }

    assert_select "p", text: I18n.t("cars.form.vin_duplicate_title")
  end

  test "create allows VIN that belongs to current user (own car)" do
    assert_difference "Car.count", 1 do
      post cars_path, params: { car: {
        make: "Toyota", model: "Supra", year: 2023,
        license_plate: "ZZ2222BB", fuel_type: "gasoline",
        vin: "WVWZZZ3CZWE123456"
      } }
    end
  end

  test "create with duplicate VIN handles case-insensitivity" do
    existing_vin = cars(:leaf).vin.downcase

    assert_no_difference "Car.count" do
      post cars_path, params: { car: {
        make: "Nissan", model: "Leaf Copy", year: 2023,
        license_plate: "ZZ3333CC", fuel_type: "electric",
        vin: existing_vin
      } }
    end
    assert_response :unprocessable_entity
  end

  test "create with blank VIN skips duplicate check" do
    assert_difference "Car.count", 1 do
      post cars_path, params: { car: {
        make: "Kia", model: "Ceed", year: 2022,
        license_plate: "ZZ4444DD", fuel_type: "gasoline",
        vin: ""
      } }
    end
  end
end
