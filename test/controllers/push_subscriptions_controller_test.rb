require "test_helper"

class PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "create stores a subscription for the current user" do
    assert_difference "@user.push_subscriptions.count", 1 do
      post push_subscriptions_path, params: {
        push_subscription: { endpoint: "https://push.example/new", p256dh_key: "p", auth_key: "a" }
      }
    end
    assert_response :created
  end

  test "create is idempotent for the same endpoint" do
    @user.push_subscriptions.create!(endpoint: "https://push.example/same", p256dh_key: "p", auth_key: "a")
    assert_no_difference "PushSubscription.count" do
      post push_subscriptions_path, params: {
        push_subscription: { endpoint: "https://push.example/same", p256dh_key: "p", auth_key: "a" }
      }
    end
    assert_response :created
  end

  test "requires authentication" do
    sign_out @user
    post push_subscriptions_path, params: {
      push_subscription: { endpoint: "https://push.example/x", p256dh_key: "p", auth_key: "a" }
    }
    assert_redirected_to new_user_session_path
  end
end
