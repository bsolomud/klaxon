require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = admins(:one)
    sign_in_admin(@admin)
  end

  # --- Authentication ---

  test "unauthenticated request redirects to admin sign in" do
    reset!
    get admin_users_path
    assert_redirected_to new_admin_session_path
  end

  # --- Index ---

  test "index lists all users" do
    get admin_users_path
    assert_response :success
    assert_select "table"
  end

  test "index displays user emails" do
    get admin_users_path
    assert_response :success
    assert_select "td", text: users(:one).email
  end

  # --- Show ---

  test "show displays user details" do
    user = users(:one)
    get admin_user_path(user)
    assert_response :success
    assert_select "dd", text: user.email
  end

  test "show displays user workshops" do
    user = users(:one)
    get admin_user_path(user)
    assert_response :success
    assert_select "p", text: workshops(:one).name
  end

  test "show displays no workshops message for user without workshops" do
    user = users(:driver_no_workshops)
    get admin_user_path(user)
    assert_response :success
    assert_select "p", text: I18n.t("admin.users.show.no_workshops")
  end
end
