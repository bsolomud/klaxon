require "test_helper"

class WebPushDelivererTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @notification = notifications(:two)
    @user.push_subscriptions.create!(endpoint: "https://push.example/a", p256dh_key: "key-a", auth_key: "auth-a")
  end

  test "configured? is false without VAPID keys" do
    assert_not WebPushDeliverer.configured?
  end

  test "does not call WebPush when not configured" do
    called = false
    WebPush.stub(:payload_send, ->(*, **) { called = true }) do
      WebPushDeliverer.new(@notification).deliver
    end
    assert_not called
  end

  test "sends a push to each subscription when configured and opted in" do
    @user.push_subscriptions.create!(endpoint: "https://push.example/b", p256dh_key: "key-b", auth_key: "auth-b")
    sent = 0
    WebPushDeliverer.stub(:configured?, true) do
      WebPush.stub(:payload_send, ->(*, **) { sent += 1 }) do
        WebPushDeliverer.new(@notification).deliver
      end
    end
    assert_equal 2, sent
  end

  test "does not send when the user disabled push" do
    @user.update!(notification_preferences: { "push" => false })
    called = false
    WebPushDeliverer.stub(:configured?, true) do
      WebPush.stub(:payload_send, ->(*, **) { called = true }) do
        WebPushDeliverer.new(@notification).deliver
      end
    end
    assert_not called
  end

  test "removes a subscription the push service reports as expired" do
    response = Struct.new(:body).new("410 Gone")
    expired = WebPush::ExpiredSubscription.new(response, "push.example")
    WebPushDeliverer.stub(:configured?, true) do
      WebPush.stub(:payload_send, ->(*, **) { raise expired }) do
        assert_difference "PushSubscription.count", -1 do
          WebPushDeliverer.new(@notification).deliver
        end
      end
    end
  end
end
