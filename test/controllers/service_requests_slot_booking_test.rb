require "test_helper"

class ServiceRequestsSlotBookingTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @car = cars(:camry)
    @workshop = workshops(:one)
    @wsc = workshop_service_categories(:tire_express)
    start = 2.days.from_now.change(hour: 10, min: 0)
    @slot = AppointmentSlot.create!(
      workshop: @workshop, workshop_service_category: @wsc,
      starts_at: start, ends_at: start + 45.minutes, capacity: 1
    )
    sign_in @user
  end

  test "booking a slot creates a request and marks the slot booked" do
    assert_difference "ServiceRequest.count", 1 do
      post service_requests_path, params: {
        service_request: {
          workshop_id: @workshop.id, car_id: @car.id,
          appointment_slot_id: @slot.id, description: "Заміна шин"
        }
      }
    end
    sr = ServiceRequest.order(:created_at).last
    assert_equal @slot.id, sr.appointment_slot_id
    assert_equal @wsc.id, sr.workshop_service_category_id
    assert_equal @slot.starts_at.to_i, sr.preferred_time.to_i
    assert_equal 1, @slot.reload.booked_count
    assert_redirected_to service_request_path(sr)
  end

  test "cannot book a slot that is already full" do
    @slot.update!(booked_count: 1) # capacity 1, now full
    assert_no_difference "ServiceRequest.count" do
      post service_requests_path, params: {
        service_request: {
          workshop_id: @workshop.id, car_id: @car.id,
          appointment_slot_id: @slot.id, description: "Заміна шин"
        }
      }
    end
    assert_response :unprocessable_entity
    assert_equal 1, @slot.reload.booked_count
  end
end
