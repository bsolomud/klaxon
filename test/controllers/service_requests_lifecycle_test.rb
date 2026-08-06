require "test_helper"

class ServiceRequestsLifecycleTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @sr = service_requests(:pending_request) # camry (user one), workshop one, pending
    sign_in @user
  end

  # --- Driver cancel ---

  test "driver can cancel a pending request and the workshop is notified" do
    operator_count = @sr.workshop.workshop_operators.count
    assert_difference "Notification.count", operator_count do
      patch cancel_service_request_path(@sr)
    end
    assert @sr.reload.cancelled?
    assert_redirected_to service_request_path(@sr)
  end

  test "driver cannot cancel a completed request" do
    completed = service_requests(:completed_request)
    patch cancel_service_request_path(completed)
    assert_not completed.reload.cancelled?
  end

  # --- Driver reschedule ---

  test "driver can reschedule a pending request to a future time" do
    new_time = 3.days.from_now.change(hour: 10, min: 0)
    patch reschedule_service_request_path(@sr), params: { service_request: { preferred_time: new_time } }
    assert_equal new_time.to_i, @sr.reload.preferred_time.to_i
    assert_redirected_to service_request_path(@sr)
  end

  test "driver cannot reschedule to a past time" do
    original = @sr.preferred_time
    patch reschedule_service_request_path(@sr), params: { service_request: { preferred_time: 2.days.ago } }
    assert_equal original.to_i, @sr.reload.preferred_time.to_i
  end

  # --- Operator cancel ---

  test "operator can cancel an accepted request and the driver is notified" do
    accepted = service_requests(:accepted_request)
    assert_difference "Notification.count", 1 do
      patch cancel_workshop_management_workshop_service_request_path(workshops(:one), accepted)
    end
    assert accepted.reload.cancelled?
  end
end
