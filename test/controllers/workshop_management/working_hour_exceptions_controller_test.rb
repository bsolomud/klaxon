require "test_helper"

class WorkshopManagement::WorkingHourExceptionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @owner = users(:one)
    @workshop = workshops(:one)
    sign_in @owner
  end

  test "owner adds a closure date" do
    date = Date.current.next_day
    assert_difference "WorkingHourException.count", 1 do
      post workshop_management_workshop_working_hour_exceptions_path(@workshop), params: { date: date.iso8601 }
    end
    assert @workshop.closed_on?(date)
  end

  test "invalid date is handled gracefully" do
    assert_no_difference "WorkingHourException.count" do
      post workshop_management_workshop_working_hour_exceptions_path(@workshop), params: { date: "not-a-date" }
    end
    assert_redirected_to workshop_management_workshop_appointment_slots_path(@workshop)
  end

  test "owner removes a closure" do
    exception = @workshop.working_hour_exceptions.create!(date: Date.current.next_day)
    assert_difference "WorkingHourException.count", -1 do
      delete workshop_management_workshop_working_hour_exception_path(@workshop, exception)
    end
  end

  test "non-manager cannot add a closure" do
    sign_in users(:driver_no_workshops)
    post workshop_management_workshop_working_hour_exceptions_path(@workshop), params: { date: Date.current.iso8601 }
    assert_response :not_found
  end
end
