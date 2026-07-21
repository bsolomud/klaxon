require "test_helper"

class WorkshopManagement::AppointmentSlotsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @owner = users(:one)
    @workshop = workshops(:one)
    @wsc = workshop_service_categories(:tire_express)
    @non_manager = users(:driver_no_workshops)
    @date = Date.current.next_day
    @workshop.working_hours.create!(day_of_week: @date.wday, opens_at: "09:00", closes_at: "11:00", closed: false)
  end

  test "owner sees the slots index" do
    sign_in @owner
    get workshop_management_workshop_appointment_slots_path(@workshop)
    assert_response :success
  end

  test "owner generates slots for a service and day" do
    sign_in @owner
    # 09:00-11:00 with 45-minute tire service = 2 slots (09:00, 09:45)
    assert_difference "AppointmentSlot.count", 2 do
      post generate_workshop_management_workshop_appointment_slots_path(@workshop),
        params: { date: @date.iso8601, workshop_service_category_id: @wsc.id }
    end
    assert_redirected_to workshop_management_workshop_appointment_slots_path(@workshop, date: @date)
  end

  test "non-manager cannot access slots" do
    sign_in @non_manager
    get workshop_management_workshop_appointment_slots_path(@workshop)
    assert_response :not_found
  end
end
