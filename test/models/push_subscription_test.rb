require "test_helper"

class PushSubscriptionTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "valid with endpoint and keys" do
    sub = @user.push_subscriptions.build(endpoint: "https://push.example/x", p256dh_key: "p", auth_key: "a")
    assert sub.valid?
  end

  test "requires endpoint" do
    sub = @user.push_subscriptions.build(p256dh_key: "p", auth_key: "a")
    assert_not sub.valid?
  end

  test "requires both keys" do
    sub = @user.push_subscriptions.build(endpoint: "https://push.example/x")
    assert_not sub.valid?
    assert_includes sub.errors.attribute_names, :p256dh_key
    assert_includes sub.errors.attribute_names, :auth_key
  end

  test "endpoint is unique across users" do
    @user.push_subscriptions.create!(endpoint: "https://push.example/dup", p256dh_key: "p", auth_key: "a")
    dup = users(:two).push_subscriptions.build(endpoint: "https://push.example/dup", p256dh_key: "p", auth_key: "a")
    assert_not dup.valid?
  end
end
