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

  # Task 111: Dashboard empty state for new users
  test "new user sees welcome hero with three cards" do
    sign_in users(:brand_new_user)
    get root_path
    assert_response :success
    assert_select "a[href='#{new_car_path}']" do
      assert_select "h3", text: I18n.t("dashboard.index.welcome_add_car")
    end
    assert_select "a[href='#{workshops_path}']" do
      assert_select "h3", text: I18n.t("dashboard.index.welcome_find_workshop")
    end
    assert_select "a[href='#{new_workshop_path}']" do
      assert_select "h3", text: I18n.t("dashboard.index.welcome_register_workshop")
    end
  end

  test "new user does not see regular dashboard sections" do
    sign_in users(:brand_new_user)
    get root_path
    assert_response :success
    assert_select "h2", text: I18n.t("dashboard.index.my_cars"), count: 0
    assert_select "h2", text: I18n.t("dashboard.index.recent_requests"), count: 0
  end

  test "user with cars sees regular dashboard instead of welcome hero" do
    get root_path
    assert_response :success
    assert_select "h2", text: I18n.t("dashboard.index.my_cars")
    assert_select "h3", text: I18n.t("dashboard.index.welcome_add_car"), count: 0
  end

  # Task 113: Dismissible welcome banner
  test "new user sees welcome banner" do
    sign_in users(:brand_new_user)
    get root_path
    assert_response :success
    assert_select "[data-controller='dismissable']", count: 1
    assert_select "h2", text: I18n.t("dashboard.index.banner_title")
  end

  test "user who dismissed banner does not see it" do
    user = users(:brand_new_user)
    user.dismiss_welcome_banner!
    sign_in user
    get root_path
    assert_response :success
    assert_select "[data-controller='dismissable']", count: 0
  end

  test "user created more than 7 days ago does not see banner" do
    user = users(:brand_new_user)
    user.update_columns(created_at: 8.days.ago)
    sign_in user
    get root_path
    assert_response :success
    assert_select "[data-controller='dismissable']", count: 0
  end

  # Task 114: First-run checklist
  test "new user sees checklist with all items unchecked" do
    sign_in users(:brand_new_user)
    get root_path
    assert_response :success
    assert_select "h2", text: I18n.t("dashboard.index.checklist_title")
    assert_select "li", minimum: 3
  end

  test "user with cars has add_car item checked" do
    sign_in users(:driver_no_workshops)
    get root_path
    assert_response :success
    assert_select ".line-through", text: I18n.t("dashboard.index.checklist_add_car")
  end

  test "checklist hidden when all items complete" do
    # User :one has cars, workshops, and service requests — all checklist items done
    get root_path
    assert_select "h2", text: I18n.t("dashboard.index.checklist_title"), count: 0
  end
end
