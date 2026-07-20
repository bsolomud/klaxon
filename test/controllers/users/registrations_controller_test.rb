require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "sign up page shows consumer copy, not the corporate template" do
    get new_user_registration_path
    assert_response :success
    assert_select "input[name='user[first_name]']"
    assert_select "input[name='user[phone_number]']"
    assert_select "input[name='intent']"
    assert_no_match(/Engineering the future of mobility/, response.body)
  end

  test "sign up stores driver intent and captures name" do
    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: { email: "newdriver@example.com", password: "password", password_confirmation: "password", first_name: "Іван" },
        intent: "driver"
      }
    end
    user = User.find_by(email: "newdriver@example.com")
    assert_equal "driver", user.onboarding_flags["intent"]
    assert_equal "Іван", user.first_name
  end

  test "sign up stores operator intent" do
    post user_registration_path, params: {
      user: { email: "newop@example.com", password: "password", password_confirmation: "password" },
      intent: "operator"
    }
    assert_equal "operator", User.find_by(email: "newop@example.com").onboarding_flags["intent"]
  end

  test "invalid intent is ignored" do
    post user_registration_path, params: {
      user: { email: "x@example.com", password: "password", password_confirmation: "password" },
      intent: "hacker"
    }
    assert_nil User.find_by(email: "x@example.com").onboarding_flags["intent"]
  end

  test "operator-intent user with no workshop is routed to workshop creation on sign in" do
    user = users(:driver_no_workshops)
    user.update!(onboarding_flags: { "intent" => "operator" })
    post user_session_path, params: { user: { email: user.email, password: "password" } }
    assert_redirected_to new_workshop_path
  end

  test "driver-intent user signs in to the dashboard" do
    user = users(:driver_no_workshops)
    user.update!(onboarding_flags: { "intent" => "driver" })
    post user_session_path, params: { user: { email: user.email, password: "password" } }
    assert_redirected_to root_path
  end
end
