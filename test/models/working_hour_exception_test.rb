require "test_helper"

class WorkingHourExceptionTest < ActiveSupport::TestCase
  setup { @workshop = workshops(:one) }

  test "requires a date" do
    assert_not WorkingHourException.new(workshop: @workshop).valid?
  end

  test "unique per workshop and date" do
    @workshop.working_hour_exceptions.create!(date: Date.current)
    dup = @workshop.working_hour_exceptions.build(date: Date.current)
    assert_not dup.valid?
  end

  test "workshop closed_on? reflects a closure" do
    assert_not @workshop.closed_on?(Date.current.next_day)
    @workshop.working_hour_exceptions.create!(date: Date.current.next_day, closed: true)
    assert @workshop.closed_on?(Date.current.next_day)
  end
end
