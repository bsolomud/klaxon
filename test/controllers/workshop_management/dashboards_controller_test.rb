require "test_helper"

class WorkshopManagement::DashboardsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @owner = users(:one)
    @workshop = workshops(:one)
    @non_manager = users(:driver_no_workshops)
  end

  test "authenticated owner sees dashboard" do
    sign_in @owner
    get workshop_management_workshop_dashboard_path(@workshop)
    assert_response :success
  end

  test "dashboard renders within workshop layout" do
    sign_in @owner
    get workshop_management_workshop_dashboard_path(@workshop)
    assert_select "aside"
    assert_select "nav"
  end

  test "dashboard shows workshop name" do
    sign_in @owner
    get workshop_management_workshop_dashboard_path(@workshop)
    assert_select "p", @workshop.name
  end

  test "dashboard shows stats cards" do
    sign_in @owner
    get workshop_management_workshop_dashboard_path(@workshop)
    assert_select "div.grid div", minimum: 3
  end

  test "unauthenticated user is redirected to sign in" do
    get workshop_management_workshop_dashboard_path(@workshop)
    assert_redirected_to new_user_session_path
  end

  test "non-manager gets 404" do
    sign_in @non_manager
    get workshop_management_workshop_dashboard_path(@workshop)
    assert_response :not_found
  end

  test "staff member can access dashboard" do
    staff = users(:two)
    sign_in staff
    get workshop_management_workshop_dashboard_path(@workshop)
    assert_response :success
  end
end
