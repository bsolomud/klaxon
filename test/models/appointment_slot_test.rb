require "test_helper"

class AppointmentSlotTest < ActiveSupport::TestCase
  def setup
    @wsc = workshop_service_categories(:tire_express)
    @workshop = workshops(:one)
  end

  def build_slot(capacity: 1, booked: 0, starts_at: 1.day.from_now)
    AppointmentSlot.create!(
      workshop: @workshop, workshop_service_category: @wsc,
      starts_at: starts_at, ends_at: starts_at + 45.minutes,
      capacity: capacity, booked_count: booked
    )
  end

  test "book! increments booked_count" do
    slot = build_slot(capacity: 2)
    slot.book!
    assert_equal 1, slot.reload.booked_count
  end

  test "book! raises when full" do
    slot = build_slot(capacity: 1, booked: 1)
    assert_raises(AppointmentSlot::Overbooked) { slot.book! }
    assert_equal 1, slot.reload.booked_count
  end

  test "cannot be booked beyond capacity across separate loads" do
    slot = build_slot(capacity: 1)
    a = AppointmentSlot.find(slot.id)
    b = AppointmentSlot.find(slot.id)
    a.book!
    assert_raises(AppointmentSlot::Overbooked) { b.book! }
    assert_equal 1, slot.reload.booked_count
  end

  test "release! decrements but never below zero" do
    slot = build_slot(capacity: 2, booked: 1)
    slot.release!
    assert_equal 0, slot.reload.booked_count
    slot.release!
    assert_equal 0, slot.reload.booked_count
  end

  test "bookable scope excludes full and past slots" do
    open_slot = build_slot(capacity: 2, booked: 1, starts_at: 1.day.from_now)
    full_slot = build_slot(capacity: 1, booked: 1, starts_at: 2.days.from_now)
    past_slot = build_slot(capacity: 1, booked: 0, starts_at: 1.day.ago)

    bookable = AppointmentSlot.bookable
    assert_includes bookable, open_slot
    assert_not_includes bookable, full_slot
    assert_not_includes bookable, past_slot
  end

  test "requires ends_at after starts_at" do
    slot = AppointmentSlot.new(
      workshop: @workshop, workshop_service_category: @wsc,
      starts_at: 1.day.from_now, ends_at: 1.day.from_now - 1.hour, capacity: 1
    )
    assert_not slot.valid?
    assert_includes slot.errors.details[:ends_at].map { |e| e[:error] }, :must_be_after_start
  end
end
