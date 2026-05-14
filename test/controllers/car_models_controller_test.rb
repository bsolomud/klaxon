require "test_helper"

class CarModelsControllerTest < ActionDispatch::IntegrationTest
  test "index returns approved models for given make" do
    toyota = car_makes(:toyota)
    get car_make_car_models_path(toyota, format: :json)
    assert_response :success

    data = JSON.parse(response.body)
    names = data.map { |m| m["name"] }

    assert_includes names, "Camry"
    assert_includes names, "Corolla"
    assert_not_includes names, "NewModel"
  end

  test "index does not require authentication" do
    toyota = car_makes(:toyota)
    get car_make_car_models_path(toyota, format: :json)
    assert_response :success
  end

  test "index returns empty for unknown make" do
    get car_make_car_models_path(car_make_id: 999999, format: :json)
    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end
end
