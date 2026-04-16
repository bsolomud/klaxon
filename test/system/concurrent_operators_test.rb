require "application_system_test_case"

class ConcurrentOperatorsTest < ApplicationSystemTestCase
  def setup
    @workshop = workshops(:one)
    @operator_a = users(:one)  # owner of workshop :one
    @operator_b = users(:two)  # staff of workshop :one
    @pending_request = service_requests(:pending_request)
  end

  test "second operator sees stale object flash when both accept same request" do
    # Both operators load the pending request page at the same time
    using_session(:operator_a) do
      sign_in_user(@operator_a)
      visit workshop_management_workshop_service_request_path(@workshop, @pending_request)
      assert_button I18n.t("workshop_management.service_requests.show.accept")
    end

    using_session(:operator_b) do
      sign_in_user(@operator_b)
      visit workshop_management_workshop_service_request_path(@workshop, @pending_request)
      assert_button I18n.t("workshop_management.service_requests.show.accept")
    end

    # Operator A clicks Accept first — succeeds
    using_session(:operator_a) do
      click_button I18n.t("workshop_management.service_requests.show.accept")
      assert_text I18n.t("workshop_management.service_requests.accept.success")
    end

    # Verify the request was accepted
    @pending_request.reload
    assert @pending_request.accepted?, "Request should now be accepted"

    # Operator B clicks Accept — gets either a stale-lock or invalid-transition alert.
    # In practice the invalid-transition check fires first because operator A's
    # commit has already flipped the status out of pending. Either outcome is an
    # acceptable safeguard; the key assertion is that the second click never
    # silently succeeds.
    using_session(:operator_b) do
      click_button I18n.t("workshop_management.service_requests.show.accept")
      stale    = I18n.t("workshop_management.service_requests.accept.stale")
      invalid  = I18n.t("workshop_management.service_requests.invalid_transition")
      assert page.has_text?(stale) || page.has_text?(invalid),
             "Expected a stale-lock or invalid-transition alert on second accept"
    end

    # Verify no data corruption — request is still in accepted state (not double-transitioned)
    @pending_request.reload
    assert @pending_request.accepted?, "Request should remain in accepted state"
  end
end
