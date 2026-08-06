require "test_helper"

class AdminSessionsControllerTest < ActionDispatch::IntegrationTest
  test "GET /admin/auth/sign_in returns 200" do
    get new_admin_session_path
    assert_response :success
  end

  test "admin sign-in route does not conflict with user sign-in route" do
    get new_user_session_path
    assert_response :success

    get new_admin_session_path
    assert_response :success
  end
end
