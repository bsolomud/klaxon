require "test_helper"

class SlotAvailabilityTest < ActiveSupport::TestCase
  def setup
    @workshop = workshops(:one)
    @wsc = workshop_service_categories(:tire_express) # 45 min duration
    @date = Date.current.next_day
    @workshop.working_hours.create!(day_of_week: @date.wday, opens_at: "09:00", closes_at: "12:00", closed: false)
  end

  test "generates back-to-back slots across working hours" do
    slots = SlotAvailability.new(@workshop, @wsc, @date).generate!
    # 09:00-12:00 = 180 minutes / 45 = 4 slots
    assert_equal 4, slots.size
    assert_equal 4, @wsc.appointment_slots.for_day(@date).count
  end

  test "is idempotent" do
    SlotAvailability.new(@workshop, @wsc, @date).generate!
    assert_no_difference "AppointmentSlot.count" do
      SlotAvailability.new(@workshop, @wsc, @date).generate!
    end
  end

  test "returns nothing on a workshop closure date" do
    @workshop.working_hour_exceptions.create!(date: @date, closed: true)
    assert_empty SlotAvailability.new(@workshop, @wsc, @date).generate!
  end

  test "returns nothing on a closed day" do
    closed_date = @date.next_day
    @workshop.working_hours.create!(day_of_week: closed_date.wday, closed: true)
    assert_empty SlotAvailability.new(@workshop, @wsc, closed_date).generate!
  end
end
