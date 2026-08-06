require "test_helper"

class DeliverNotificationJobTest < ActiveJob::TestCase
  # Records SMS messages instead of sending them.
  class RecordingSms
    attr_reader :messages

    def initialize
      @messages = []
    end

    def deliver(to:, body:)
      @messages << { to: to, body: body }
    end
  end

  setup do
    @user = users(:one)
    @recorder = RecordingSms.new
    @original_adapter = Sms.adapter
    Sms.adapter = @recorder
  end

  teardown do
    Sms.adapter = @original_adapter
  end

  test "creating a notification enqueues delivery" do
    assert_enqueued_with(job: DeliverNotificationJob) do
      Notification.create!(user: @user, notifiable: workshops(:one), event: :workshop_approved)
    end
  end

  test "performs web push delivery for the notification" do
    notification = notifications(:two)
    @user.push_subscriptions.create!(endpoint: "https://push.example/job", p256dh_key: "p", auth_key: "a")
    sent = 0
    WebPushDeliverer.stub(:configured?, true) do
      WebPush.stub(:payload_send, ->(*, **) { sent += 1 }) do
        DeliverNotificationJob.new.perform(notification)
      end
    end
    assert_equal 1, sent
  end

  test "sends an SMS for an urgent event when the user has a phone number" do
    @user.update!(phone_number: "+380671234567")
    notification = Notification.create!(user: @user, notifiable: queue_entries(:waiting_entry), event: :queue_called)

    DeliverNotificationJob.new.perform(notification)

    assert_equal 1, @recorder.messages.size
    assert_equal @user.phone_number, @recorder.messages.first[:to]
  end

  test "does not send an SMS for a non-urgent event" do
    @user.update!(phone_number: "+380671234567")
    DeliverNotificationJob.new.perform(notifications(:two))
    assert_empty @recorder.messages
  end

  test "does not send an SMS when the user has no phone number" do
    notification = Notification.create!(user: @user, notifiable: queue_entries(:waiting_entry), event: :queue_called)
    DeliverNotificationJob.new.perform(notification)
    assert_empty @recorder.messages
  end
end
