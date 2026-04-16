require "test_helper"

class WorkshopManagement::ServiceRecordsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @owner = users(:one)
    @workshop = workshops(:one)
    @in_progress_request = service_requests(:in_progress_no_record)
    @non_manager = users(:driver_no_workshops)
  end

  # === New ===

  test "new renders form for in_progress request" do
    sign_in @owner
    get new_workshop_management_workshop_service_request_service_record_path(@workshop, @in_progress_request)
    assert_response :success
    assert_select "form"
    assert_select "textarea[name='service_record[summary]']"
  end

  test "new pre-fills odometer from car" do
    sign_in @owner
    get new_workshop_management_workshop_service_request_service_record_path(@workshop, @in_progress_request)
    assert_select "input[name='service_record[odometer_at_service]'][value='50000']"
  end

  test "new requires authentication" do
    get new_workshop_management_workshop_service_request_service_record_path(@workshop, @in_progress_request)
    assert_redirected_to new_user_session_path
  end

  test "new denies non-manager" do
    sign_in @non_manager
    get new_workshop_management_workshop_service_request_service_record_path(@workshop, @in_progress_request)
    assert_response :not_found
  end

  test "new rejects non-in_progress request" do
    sign_in @owner
    pending_request = service_requests(:pending_request)
    get new_workshop_management_workshop_service_request_service_record_path(@workshop, pending_request)
    assert_response :not_found
  end

  # === Create ===

  test "create saves service record and completes request" do
    sign_in @owner
    assert_difference "ServiceRecord.count", 1 do
      post workshop_management_workshop_service_request_service_record_path(@workshop, @in_progress_request),
           params: { service_record: {
             summary: "Замінено масло та фільтр",
             recommendations: "Перевірити через 10000 км",
             performed_by: "Іван",
             odometer_at_service: 55000,
             labor_cost: 500,
             parts_cost: 1200,
             next_service_at_km: 65000,
             next_service_at_date: "2027-06-01"
           } }
    end

    assert_redirected_to workshop_management_workshop_service_request_path(@workshop, @in_progress_request)
    assert @in_progress_request.reload.completed?
    assert_equal "Замінено масло та фільтр", @in_progress_request.service_record.summary
  end

  test "create updates car odometer" do
    sign_in @owner
    post workshop_management_workshop_service_request_service_record_path(@workshop, @in_progress_request),
         params: { service_record: {
           summary: "Тест пробігу",
           odometer_at_service: 60000
         } }

    assert_equal 60000, @in_progress_request.car.reload.odometer
  end

  test "create renders form on validation error" do
    sign_in @owner
    assert_no_difference "ServiceRecord.count" do
      post workshop_management_workshop_service_request_service_record_path(@workshop, @in_progress_request),
           params: { service_record: { summary: "" } }
    end

    assert_response :unprocessable_entity
    assert_select "form"
  end

  test "create does not complete request on validation error" do
    sign_in @owner
    post workshop_management_workshop_service_request_service_record_path(@workshop, @in_progress_request),
         params: { service_record: { summary: "" } }

    assert @in_progress_request.reload.in_progress?
  end

  test "create requires authentication" do
    post workshop_management_workshop_service_request_service_record_path(@workshop, @in_progress_request),
         params: { service_record: { summary: "Тест" } }
    assert_redirected_to new_user_session_path
  end

  test "create denies non-manager" do
    sign_in @non_manager
    post workshop_management_workshop_service_request_service_record_path(@workshop, @in_progress_request),
         params: { service_record: { summary: "Тест" } }
    assert_response :not_found
  end

  test "create rejects non-in_progress request" do
    sign_in @owner
    accepted_request = service_requests(:accepted_request)
    post workshop_management_workshop_service_request_service_record_path(@workshop, accepted_request),
         params: { service_record: { summary: "Тест" } }
    assert_response :not_found
  end

  # === Show button on service request show ===

  test "service request show displays complete button for in_progress request" do
    sign_in @owner
    get workshop_management_workshop_service_request_path(@workshop, @in_progress_request)
    assert_select "a", text: I18n.t("workshop_management.service_requests.show.complete")
  end

  test "create enqueues completed email and notification" do
    sign_in @owner
    driver = @in_progress_request.car.user
    assert_enqueued_email_with ServiceRequestMailer, :completed, params: { service_request: @in_progress_request } do
      assert_difference -> { Notification.where(user: driver, notifiable: @in_progress_request, event: :service_request_completed).count }, 1 do
        post workshop_management_workshop_service_request_service_record_path(@workshop, @in_progress_request),
             params: { service_record: { summary: "Готово", odometer_at_service: 60000 } }
      end
    end
  end

  test "create does not enqueue completed email on validation error" do
    sign_in @owner
    assert_no_enqueued_emails do
      post workshop_management_workshop_service_request_service_record_path(@workshop, @in_progress_request),
           params: { service_record: { summary: "" } }
    end
  end
end
