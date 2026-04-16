require "test_helper"

class ServiceRequestMailerTest < ActionMailer::TestCase
  setup do
    @request = service_requests(:pending_request)
    @workshop = @request.workshop
    @driver = @request.car.user
  end

  test "created sends email to workshop operators" do
    email = ServiceRequestMailer.with(service_request: @request).created
    email.deliver_now

    expected_emails = @workshop.workshop_operators.includes(:user).map { |op| op.user.email }
    assert_not_empty expected_emails
    expected_emails.each { |e| assert_includes email.to, e }
    assert_match @workshop.name, email.subject
    assert_match @request.car.make, email.html_part.body.to_s
    assert_match @request.workshop_service_category.service_category.name, email.html_part.body.to_s
  end

  test "accepted sends email to driver" do
    email = ServiceRequestMailer.with(service_request: @request).accepted
    email.deliver_now

    assert_equal [@driver.email], email.to
    assert_match @workshop.name, email.html_part.body.to_s
  end

  test "rejected sends email to driver" do
    email = ServiceRequestMailer.with(service_request: @request).rejected
    email.deliver_now

    assert_equal [@driver.email], email.to
    assert_match @workshop.name, email.html_part.body.to_s
  end

  test "started sends email to driver" do
    email = ServiceRequestMailer.with(service_request: @request).started
    email.deliver_now

    assert_equal [@driver.email], email.to
    assert_match @workshop.name, email.html_part.body.to_s
  end

  test "completed sends email to driver" do
    completed = service_requests(:completed_request)
    email = ServiceRequestMailer.with(service_request: completed).completed
    email.deliver_now

    assert_equal [completed.car.user.email], email.to
    assert_match completed.workshop.name, email.html_part.body.to_s
  end
end
