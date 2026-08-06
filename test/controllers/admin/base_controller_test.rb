require "test_helper"

class Admin::BaseControllerTest < ActionDispatch::IntegrationTest
  test "unauthenticated request to admin route redirects to admin sign in" do
    get admin_root_path
    assert_redirected_to new_admin_session_path
  end

  test "authenticated admin can access admin routes" do
    admin = admins(:one)
    sign_in_admin(admin)

    get admin_root_path
    assert_response :success
  end

  test "authenticated user cannot access admin routes" do
    user = users(:one)
    sign_in_user(user)

    get admin_root_path
    assert_redirected_to new_admin_session_path
  end

  private

  def sign_in_user(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password" }
    }
  end
end
