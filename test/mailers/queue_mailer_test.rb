require "test_helper"

class QueueMailerTest < ActionMailer::TestCase
  setup do
    @entry = queue_entries(:waiting_entry)
    @driver = @entry.user
    @workshop = @entry.service_queue.workshop
  end

  test "called sends email to driver with workshop details" do
    email = QueueMailer.with(queue_entry: @entry).called
    email.deliver_now

    assert_equal [@driver.email], email.to
    assert_match @workshop.name, email.subject
    assert_match @workshop.name, email.html_part.body.to_s
    assert_match @entry.position.to_s, email.html_part.body.to_s
  end
end
