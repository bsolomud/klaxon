require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    sign_in @user
  end

  test "index returns success" do
    get root_path
    assert_response :success
  end

  test "index requires authentication" do
    sign_out @user
    get root_path
    assert_redirected_to new_user_session_path
  end

  test "index shows my cars section" do
    get root_path
    assert_response :success
    assert_select "h2", text: I18n.t("dashboard.index.my_cars")
  end

  test "index shows recent service requests" do
    get root_path
    assert_response :success
    assert_select "h2", text: I18n.t("dashboard.index.recent_requests")
  end

  test "index shows find workshop CTA" do
    get root_path
    assert_response :success
    assert_select "a[href='#{workshops_path}']", text: I18n.t("dashboard.index.find_workshop")
  end

  test "index shows my workshops section for user who manages workshops" do
    get root_path
    assert_response :success
    assert_select "h2", text: I18n.t("dashboard.index.my_workshops")
  end

  test "index hides my workshops section for user without workshops" do
    sign_in users(:driver_no_workshops)
    get root_path
    assert_response :success
    assert_select "h2", text: I18n.t("dashboard.index.my_workshops"), count: 0
  end

  test "index shows no cars message when user has no cars" do
    user = users(:three)
    user.cars.destroy_all
    sign_in user
    get root_path
    assert_response :success
    assert_select "p", text: I18n.t("dashboard.index.no_cars")
  end

  test "navigation shows all links" do
    get root_path
    assert_select "nav a[href='#{workshops_path}']"
    assert_select "nav a[href='#{cars_path}']"
    assert_select "nav a[href='#{service_requests_path}']"
  end

  test "navigation shows my workshops link for user who manages workshops" do
    get root_path
    assert_select "nav a[href='#{my_workshops_path}']"
  end

  test "navigation hides my workshops link for user without workshops" do
    sign_in users(:driver_no_workshops)
    get root_path
    assert_select "nav a[href='#{my_workshops_path}']", count: 0
  end
end
