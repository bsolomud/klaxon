require "test_helper"

class WorkshopOperatorTest < ActiveSupport::TestCase
  def setup
    @operator = workshop_operators(:owner_one)
  end

  test "defaults to owner role" do
    wo = WorkshopOperator.new
    assert wo.owner?
  end

  test "owner? returns true for owner role" do
    assert @operator.owner?
  end

  test "staff? returns true for staff role" do
    staff = workshop_operators(:staff_two)
    assert staff.staff?
  end

  test "belongs to user" do
    assert_equal users(:one), @operator.user
  end

  test "belongs to workshop" do
    assert_equal workshops(:one), @operator.workshop
  end

  test "duplicate user_id and workshop_id raises error" do
    duplicate = WorkshopOperator.new(
      user: users(:one),
      workshop: workshops(:one),
      role: :staff
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "duplicate user_id and workshop_id violates unique index" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      WorkshopOperator.new(
        user_id: users(:one).id,
        workshop_id: workshops(:one).id,
        role: :staff
      ).save(validate: false)
    end
  end

  test "same user can operate different workshops" do
    wo = WorkshopOperator.new(
      user: users(:one),
      workshop: workshops(:two),
      role: :owner
    )
    assert wo.valid?
  end
end
