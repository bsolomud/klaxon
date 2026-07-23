require "test_helper"

class CarHistoryAccessesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @car = cars(:camry) # user one
    @workshop = workshops(:one)
    sign_in @user
  end

  test "granting access creates a record" do
    assert_difference "CarHistoryAccess.count", 1 do
      post car_history_accesses_path, params: { car_id: @car.id, workshop_id: @workshop.id }
    end
    assert @car.history_visible_to?(@workshop)
    assert_redirected_to car_path(@car)
  end

  test "granting is idempotent" do
    CarHistoryAccess.create!(car: @car, workshop: @workshop)
    assert_no_difference "CarHistoryAccess.count" do
      post car_history_accesses_path, params: { car_id: @car.id, workshop_id: @workshop.id }
    end
  end

  test "revoking removes access" do
    access = CarHistoryAccess.create!(car: @car, workshop: @workshop)
    assert_difference "CarHistoryAccess.count", -1 do
      delete car_history_access_path(access)
    end
    assert_not @car.reload.history_visible_to?(@workshop)
  end

  test "cannot grant access for another user's car" do
    other = cars(:other_user_car)
    assert_no_difference "CarHistoryAccess.count" do
      post car_history_accesses_path, params: { car_id: other.id, workshop_id: @workshop.id }
    end
    assert_response :not_found
  end

  test "cannot revoke another user's access" do
    other = cars(:other_user_car)
    access = CarHistoryAccess.create!(car: other, workshop: @workshop)
    delete car_history_access_path(access)
    assert_response :not_found
    assert CarHistoryAccess.exists?(access.id)
  end

  test "operator sees car history only when the driver grants access" do
    request = service_requests(:pending_request) # camry, workshop one
    not_shared = I18n.t("workshop_management.service_requests.show.history_not_shared")

    get workshop_management_workshop_service_request_path(@workshop, request)
    assert_select "p", text: not_shared

    CarHistoryAccess.create!(car: @car, workshop: @workshop)
    get workshop_management_workshop_service_request_path(@workshop, request)
    assert_select "p", text: not_shared, count: 0
  end
end
