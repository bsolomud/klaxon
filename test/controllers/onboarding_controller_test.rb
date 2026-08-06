require "test_helper"

class OnboardingControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:brand_new_user)
    sign_in @user
  end

  test "dismiss welcome banner stores flag" do
    patch onboarding_path(flag: :welcome_dismissed)
    assert_response :ok
    @user.reload
    assert_equal true, @user.onboarding_flags["welcome_dismissed"]
    assert @user.onboarding_flags["welcome_dismissed_at"].present?
  end

  test "dismiss welcome banner requires authentication" do
    sign_out @user
    patch onboarding_path(flag: :welcome_dismissed)
    assert_redirected_to new_user_session_path
  end

  test "unknown flag does nothing" do
    patch onboarding_path(flag: :unknown)
    assert_response :ok
    @user.reload
    assert_equal({}, @user.onboarding_flags)
  end
end
