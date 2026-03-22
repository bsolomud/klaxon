require "test_helper"

class WorkshopTest < ActiveSupport::TestCase
  def setup
    @workshop = workshops(:one)
  end

  test "has operators through workshop_operators" do
    assert_includes @workshop.operators, users(:one)
    assert_includes @workshop.operators, users(:two)
  end

  test "operators returns only users linked via workshop_operators" do
    assert_not_includes @workshop.operators, User.create!(
      email: "unlinked@example.com",
      password: "password"
    )
  end

  test "destroying workshop destroys workshop_operators" do
    assert_difference "WorkshopOperator.count", -2 do
      @workshop.destroy
    end
  end

  # Task 10 — status enum

  test "defaults to pending status" do
    workshop = Workshop.new
    assert workshop.pending?
  end

  test "active scope returns only active workshops" do
    active_workshops = Workshop.active
    assert_includes active_workshops, workshops(:one)
    assert_includes active_workshops, workshops(:two)
    assert_not_includes active_workshops, workshops(:pending_workshop)
  end

  test "status transitions work" do
    workshop = workshops(:pending_workshop)
    assert workshop.pending?

    workshop.active!
    assert workshop.active?

    workshop.suspended!
    assert workshop.suspended?
  end

  test "can transition to declined with decline_reason" do
    workshop = workshops(:pending_workshop)
    workshop.declined!
    workshop.update!(decline_reason: "Не відповідає вимогам")

    assert workshop.declined?
    assert_equal "Не відповідає вимогам", workshop.decline_reason
  end

  test "decline_reason is nullable" do
    assert_nil @workshop.decline_reason
  end
end
