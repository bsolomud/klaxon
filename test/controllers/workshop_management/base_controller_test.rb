require "test_helper"

class WorkshopManagement::BaseControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @owner = users(:one)
    @workshop = workshops(:one)
    @non_manager = users(:driver_no_workshops)
    @pending_owner = users(:three)
    @pending_workshop = workshops(:pending_workshop)
  end

  test "authenticated owner can access workshop management" do
    sign_in @owner
    get workshop_management_workshop_path(@workshop)
    assert_response :success
  end

  test "unauthenticated user is redirected to sign in" do
    get workshop_management_workshop_path(@workshop)
    assert_redirected_to new_user_session_path
  end

  test "user who does not manage workshop gets 404 via scoped find" do
    sign_in @non_manager
    get workshop_management_workshop_path(@workshop)
    assert_response :not_found
  end

  test "owner of pending workshop gets 404 because scoped find filters inactive" do
    sign_in @pending_owner
    get workshop_management_workshop_path(@pending_workshop)
    assert_response :not_found
  end

  test "workshop context is always resolved from URL params" do
    sign_in @owner
    get workshop_management_workshop_path(@workshop)
    assert_response :success
    assert_select "h2", @workshop.name
  end

  test "renders workshop layout with sidebar" do
    sign_in @owner
    get workshop_management_workshop_path(@workshop)
    assert_response :success
    assert_select "aside"
    assert_select "nav"
  end

  test "staff member can access workshop management" do
    staff = users(:two)
    sign_in staff
    get workshop_management_workshop_path(@workshop)
    assert_response :success
  end
end
