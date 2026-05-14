require "test_helper"

class CarMakesControllerTest < ActionDispatch::IntegrationTest
  test "index returns only approved makes as JSON" do
    get car_makes_path(format: :json)
    assert_response :success

    data = JSON.parse(response.body)
    names = data.map { |m| m["name"] }

    assert_includes names, "Toyota"
    assert_not_includes names, "NewBrand"
    assert_not_includes names, "FakeBrand"
  end

  test "index does not require authentication" do
    get car_makes_path(format: :json)
    assert_response :success
  end
end
