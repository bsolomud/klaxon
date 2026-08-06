require "test_helper"

class WorkshopManagement::ServiceRequestsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @owner = users(:one)
    @workshop = workshops(:one)
    @pending_request = service_requests(:pending_request)
    @accepted_request = service_requests(:accepted_request)
    @in_progress_request = service_requests(:in_progress_request)
    @non_manager = users(:driver_no_workshops)
  end

  # === Index ===

  test "index shows workshop service requests" do
    sign_in @owner
    get workshop_management_workshop_service_requests_path(@workshop)
    assert_response :success
    assert_select "table"
  end

  test "index scoped to current workshop" do
    sign_in @owner
    get workshop_management_workshop_service_requests_path(@workshop)
    assert_response :success
    assert_select "td", text: @pending_request.car.display_name
  end

  test "index filters by status" do
    sign_in @owner
    get workshop_management_workshop_service_requests_path(@workshop, status: "accepted")
    assert_response :success
    assert_select "td", text: @accepted_request.car.display_name
  end

  test "index without status filter shows all requests" do
    sign_in @owner
    get workshop_management_workshop_service_requests_path(@workshop)
    assert_response :success
  end

  test "index requires authentication" do
    get workshop_management_workshop_service_requests_path(@workshop)
    assert_redirected_to new_user_session_path
  end

  test "index denies non-manager" do
    sign_in @non_manager
    get workshop_management_workshop_service_requests_path(@workshop)
    assert_response :not_found
  end

  # === Show ===

  test "show displays request details" do
    sign_in @owner
    get workshop_management_workshop_service_request_path(@workshop, @pending_request)
    assert_response :success
    assert_select "dd", text: @pending_request.car.display_name
  end

  test "show displays driver email" do
    sign_in @owner
    get workshop_management_workshop_service_request_path(@workshop, @pending_request)
    assert_select "dd", text: @pending_request.car.user.email
  end

  test "show displays description" do
    sign_in @owner
    get workshop_management_workshop_service_request_path(@workshop, @pending_request)
    assert_response :success
  end

  test "show requires authentication" do
    get workshop_management_workshop_service_request_path(@workshop, @pending_request)
    assert_redirected_to new_user_session_path
  end

  test "show denies non-manager" do
    sign_in @non_manager
    get workshop_management_workshop_service_request_path(@workshop, @pending_request)
    assert_response :not_found
  end

  test "cannot show request from another workshop" do
    other_request = service_requests(:other_user_request)
    sign_in @owner
    get workshop_management_workshop_service_request_path(@workshop, other_request)
    assert_response :not_found
  end

  # === Accept ===

  test "accept transitions pending request to accepted" do
    sign_in @owner
    patch accept_workshop_management_workshop_service_request_path(@workshop, @pending_request),
          params: { lock_version: @pending_request.lock_version }
    assert_redirected_to workshop_management_workshop_service_request_path(@workshop, @pending_request)
    assert @pending_request.reload.accepted?
  end

  test "accept handles stale object error" do
    sign_in @owner
    patch accept_workshop_management_workshop_service_request_path(@workshop, @pending_request),
          params: { lock_version: @pending_request.lock_version + 999 }
    assert_redirected_to workshop_management_workshop_service_request_path(@workshop, @pending_request)
    assert_equal I18n.t("workshop_management.service_requests.accept.stale"), flash[:alert]
  end

  test "accept requires authentication" do
    patch accept_workshop_management_workshop_service_request_path(@workshop, @pending_request),
          params: { lock_version: 0 }
    assert_redirected_to new_user_session_path
  end

  test "accept denies non-manager" do
    sign_in @non_manager
    patch accept_workshop_management_workshop_service_request_path(@workshop, @pending_request),
          params: { lock_version: 0 }
    assert_response :not_found
  end

  # === Reject ===

  test "reject transitions pending request to rejected" do
    sign_in @owner
    patch reject_workshop_management_workshop_service_request_path(@workshop, @pending_request),
          params: { lock_version: @pending_request.lock_version }
    assert_redirected_to workshop_management_workshop_service_request_path(@workshop, @pending_request)
    assert @pending_request.reload.rejected?
  end

  test "reject handles stale object error" do
    sign_in @owner
    patch reject_workshop_management_workshop_service_request_path(@workshop, @pending_request),
          params: { lock_version: @pending_request.lock_version + 999 }
    assert_redirected_to workshop_management_workshop_service_request_path(@workshop, @pending_request)
    assert_equal I18n.t("workshop_management.service_requests.reject.stale"), flash[:alert]
  end

  test "reject requires authentication" do
    patch reject_workshop_management_workshop_service_request_path(@workshop, @pending_request),
          params: { lock_version: 0 }
    assert_redirected_to new_user_session_path
  end

  # === Start ===

  test "start transitions accepted request to in_progress" do
    sign_in @owner
    patch start_workshop_management_workshop_service_request_path(@workshop, @accepted_request),
          params: { lock_version: @accepted_request.lock_version }
    assert_redirected_to workshop_management_workshop_service_request_path(@workshop, @accepted_request)
    assert @accepted_request.reload.in_progress?
  end

  test "start handles stale object error" do
    sign_in @owner
    patch start_workshop_management_workshop_service_request_path(@workshop, @accepted_request),
          params: { lock_version: @accepted_request.lock_version + 999 }
    assert_redirected_to workshop_management_workshop_service_request_path(@workshop, @accepted_request)
    assert_equal I18n.t("workshop_management.service_requests.start.stale"), flash[:alert]
  end

  test "start requires authentication" do
    patch start_workshop_management_workshop_service_request_path(@workshop, @accepted_request),
          params: { lock_version: 0 }
    assert_redirected_to new_user_session_path
  end

  test "start denies non-manager" do
    sign_in @non_manager
    patch start_workshop_management_workshop_service_request_path(@workshop, @accepted_request),
          params: { lock_version: 0 }
    assert_response :not_found
  end

  # === Show action buttons ===

  test "show displays accept and reject buttons for pending request" do
    sign_in @owner
    get workshop_management_workshop_service_request_path(@workshop, @pending_request)
    assert_select "button", text: I18n.t("workshop_management.service_requests.show.accept")
    assert_select "button", text: I18n.t("workshop_management.service_requests.show.reject")
  end

  test "show displays start button for accepted request" do
    sign_in @owner
    get workshop_management_workshop_service_request_path(@workshop, @accepted_request)
    assert_select "button", text: I18n.t("workshop_management.service_requests.show.start")
  end

  test "show displays no action buttons for in_progress request" do
    sign_in @owner
    get workshop_management_workshop_service_request_path(@workshop, @in_progress_request)
    assert_select "button", text: I18n.t("workshop_management.service_requests.show.accept"), count: 0
    assert_select "button", text: I18n.t("workshop_management.service_requests.show.start"), count: 0
  end

  test "staff member can access service requests" do
    staff = users(:two)
    sign_in staff
    get workshop_management_workshop_service_requests_path(@workshop)
    assert_response :success
  end

  # === Hidden lock_version in forms ===

  test "show includes lock_version in action forms" do
    sign_in @owner
    get workshop_management_workshop_service_request_path(@workshop, @pending_request)
    assert_select "input[name='lock_version']", minimum: 1
  end

  # === Invalid state transitions ===

  test "accept rejects non-pending request" do
    sign_in @owner
    patch accept_workshop_management_workshop_service_request_path(@workshop, @accepted_request),
          params: { lock_version: @accepted_request.lock_version }
    assert_redirected_to workshop_management_workshop_service_request_path(@workshop, @accepted_request)
    assert_equal I18n.t("workshop_management.service_requests.invalid_transition"), flash[:alert]
    assert @accepted_request.reload.accepted?
  end

  test "reject rejects non-pending request" do
    sign_in @owner
    patch reject_workshop_management_workshop_service_request_path(@workshop, @in_progress_request),
          params: { lock_version: @in_progress_request.lock_version }
    assert_redirected_to workshop_management_workshop_service_request_path(@workshop, @in_progress_request)
    assert_equal I18n.t("workshop_management.service_requests.invalid_transition"), flash[:alert]
    assert @in_progress_request.reload.in_progress?
  end

  test "start rejects non-accepted request" do
    sign_in @owner
    patch start_workshop_management_workshop_service_request_path(@workshop, @pending_request),
          params: { lock_version: @pending_request.lock_version }
    assert_redirected_to workshop_management_workshop_service_request_path(@workshop, @pending_request)
    assert_equal I18n.t("workshop_management.service_requests.invalid_transition"), flash[:alert]
    assert @pending_request.reload.pending?
  end

  # === Mailer / notification side effects ===

  test "accept enqueues accepted email and notification" do
    sign_in @owner
    assert_enqueued_email_with ServiceRequestMailer, :accepted, params: { service_request: @pending_request } do
      assert_difference -> { Notification.where(notifiable: @pending_request, event: :service_request_accepted).count }, 1 do
        patch accept_workshop_management_workshop_service_request_path(@workshop, @pending_request),
              params: { lock_version: @pending_request.lock_version }
      end
    end
  end

  test "reject enqueues rejected email and notification" do
    sign_in @owner
    assert_enqueued_email_with ServiceRequestMailer, :rejected, params: { service_request: @pending_request } do
      assert_difference -> { Notification.where(notifiable: @pending_request, event: :service_request_rejected).count }, 1 do
        patch reject_workshop_management_workshop_service_request_path(@workshop, @pending_request),
              params: { lock_version: @pending_request.lock_version }
      end
    end
  end

  test "start enqueues started email and notification" do
    sign_in @owner
    assert_enqueued_email_with ServiceRequestMailer, :started, params: { service_request: @accepted_request } do
      assert_difference -> { Notification.where(notifiable: @accepted_request, event: :service_request_started).count }, 1 do
        patch start_workshop_management_workshop_service_request_path(@workshop, @accepted_request),
              params: { lock_version: @accepted_request.lock_version }
      end
    end
  end

  test "accept does not enqueue email on stale object error" do
    sign_in @owner
    assert_no_enqueued_emails do
      patch accept_workshop_management_workshop_service_request_path(@workshop, @pending_request),
            params: { lock_version: @pending_request.lock_version + 999 }
    end
  end

  test "accept does not enqueue email on invalid state" do
    sign_in @owner
    assert_no_enqueued_emails do
      patch accept_workshop_management_workshop_service_request_path(@workshop, @accepted_request),
            params: { lock_version: @accepted_request.lock_version }
    end
  end
end
