require "test_helper"

class ServiceCategoriesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @category = service_categories(:tire_service)
  end

  # index and show are public (authenticate_user! is skipped)

  test "index is publicly accessible without authentication" do
    get service_categories_path
    assert_response :success
  end

  test "index lists all categories" do
    get service_categories_path
    assert_match service_categories(:tire_service).name, @response.body
    assert_match service_categories(:car_wash).name, @response.body
  end

  test "show is publicly accessible without authentication" do
    get service_category_path(@category)
    assert_response :success
  end
end
