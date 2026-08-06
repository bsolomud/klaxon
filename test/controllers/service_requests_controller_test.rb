require "test_helper"

class ServiceRequestsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @request_record = service_requests(:pending_request)
    @workshop = workshops(:one)
    @wsc = workshop_service_categories(:tire_express)
    sign_in @user
  end

  # --- Index ---

  test "index returns success" do
    get service_requests_path
    assert_response :success
  end

  test "index shows only current user's cars' requests" do
    get service_requests_path
    assert_response :success
    # pending_request and accepted_request belong to camry (user :one)
    assert_select "td", text: @workshop.name
    # other_user_request belongs to leaf (user :two) — should not appear
    assert_select "td", text: workshops(:two).name, count: 0
  end

  test "index requires authentication" do
    sign_out @user
    get service_requests_path
    assert_redirected_to new_user_session_path
  end

  # --- Show ---

  test "show returns success for own request" do
    get service_request_path(@request_record)
    assert_response :success
  end

  test "show displays request details" do
    get service_request_path(@request_record)
    assert_response :success
    assert_select "dd", text: /#{@workshop.name}/
  end

  test "cannot view another user's request" do
    other_request = service_requests(:other_user_request)
    get service_request_path(other_request)
    assert_response :not_found
  end

  test "show requires authentication" do
    sign_out @user
    get service_request_path(@request_record)
    assert_redirected_to new_user_session_path
  end

  # --- New ---

  test "new returns success with workshop_id" do
    get new_service_request_path(workshop_id: @workshop.id)
    assert_response :success
  end

  test "new renders form with car and category selects" do
    get new_service_request_path(workshop_id: @workshop.id)
    assert_select "form[action=?]", service_requests_path
    assert_select "select[name='service_request[car_id]']"
    assert_select "select[name='service_request[workshop_service_category_id]']"
  end

  test "new requires authentication" do
    sign_out @user
    get new_service_request_path(workshop_id: @workshop.id)
    assert_redirected_to new_user_session_path
  end

  test "new rejects non-active workshop" do
    get new_service_request_path(workshop_id: workshops(:pending_workshop).id)
    assert_response :not_found
  end

  # --- Create ---

  test "create saves service request and redirects" do
    assert_difference "ServiceRequest.count", 1 do
      post service_requests_path, params: { service_request: {
        car_id: cars(:camry).id,
        workshop_id: @workshop.id,
        workshop_service_category_id: @wsc.id,
        description: "Потрібна заміна гуми",
        preferred_time: 2.days.from_now
      } }
    end

    sr = ServiceRequest.last
    assert_redirected_to service_request_path(sr)
    assert_equal I18n.t("service_requests.create.success"), flash[:notice]
    assert sr.price_snapshot.present?
  end

  test "create enqueues created email and creates notifications for operators" do
    operator_ids = @workshop.workshop_operators.pluck(:user_id)
    assert_enqueued_emails 1 do
      assert_difference -> { Notification.where(event: :service_request_created, user_id: operator_ids).count }, operator_ids.size do
        post service_requests_path, params: { service_request: {
          car_id: cars(:camry).id,
          workshop_id: @workshop.id,
          workshop_service_category_id: @wsc.id,
          description: "Notify test",
          preferred_time: 2.days.from_now
        } }
      end
    end
  end

  test "create does not enqueue email on validation error" do
    assert_no_enqueued_emails do
      post service_requests_path, params: { service_request: {
        car_id: cars(:camry).id,
        workshop_id: @workshop.id,
        workshop_service_category_id: @wsc.id,
        description: "",
        preferred_time: nil
      } }
    end
  end

  test "create re-renders form on validation error" do
    assert_no_difference "ServiceRequest.count" do
      post service_requests_path, params: { service_request: {
        car_id: cars(:camry).id,
        workshop_id: @workshop.id,
        workshop_service_category_id: @wsc.id,
        description: "",
        preferred_time: nil
      } }
    end
    assert_response :unprocessable_entity
  end

  test "create prevents using another user's car" do
    assert_no_difference "ServiceRequest.count" do
      post service_requests_path, params: { service_request: {
        car_id: cars(:leaf).id,
        workshop_id: @workshop.id,
        workshop_service_category_id: @wsc.id,
        description: "Attempt",
        preferred_time: 2.days.from_now
      } }
    end
    assert_response :not_found
  end

  test "create requires authentication" do
    sign_out @user
    post service_requests_path, params: { service_request: {
      car_id: cars(:camry).id,
      workshop_id: @workshop.id,
      workshop_service_category_id: @wsc.id,
      description: "Test",
      preferred_time: 2.days.from_now
    } }
    assert_redirected_to new_user_session_path
  end
end
