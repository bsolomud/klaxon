require "test_helper"

class WorkingHourTest < ActiveSupport::TestCase
  def setup
    @workshop = workshops(:one)
  end

  test "valid with open hours" do
    wh = @workshop.working_hours.build(
      day_of_week: 1, opens_at: "08:00", closes_at: "18:00", closed: false
    )
    assert wh.valid?
  end

  test "requires day_of_week within 0..6" do
    wh = @workshop.working_hours.build(
      day_of_week: 7, opens_at: "08:00", closes_at: "18:00"
    )
    assert_not wh.valid?
    assert wh.errors[:day_of_week].any?
  end

  test "requires opens_at when not closed" do
    wh = @workshop.working_hours.build(
      day_of_week: 2, opens_at: nil, closes_at: "18:00", closed: false
    )
    assert_not wh.valid?
    assert_includes wh.errors[:opens_at], I18n.t("activerecord.errors.messages.blank")
  end

  test "requires closes_at when not closed" do
    wh = @workshop.working_hours.build(
      day_of_week: 2, opens_at: "08:00", closes_at: nil, closed: false
    )
    assert_not wh.valid?
    assert_includes wh.errors[:closes_at], I18n.t("activerecord.errors.messages.blank")
  end

  test "does not require opens_at or closes_at when closed" do
    wh = @workshop.working_hours.build(
      day_of_week: 3, opens_at: nil, closes_at: nil, closed: true
    )
    assert wh.valid?
  end

  test "enforces unique day_of_week per workshop" do
    @workshop.working_hours.create!(day_of_week: 4, opens_at: "08:00", closes_at: "18:00")
    duplicate = @workshop.working_hours.build(day_of_week: 4, opens_at: "09:00", closes_at: "17:00")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:day_of_week], I18n.t("activerecord.errors.messages.taken")
  end

  test "belongs to a workshop" do
    wh = @workshop.working_hours.build(day_of_week: 5, opens_at: "08:00", closes_at: "18:00")
    assert_equal @workshop, wh.workshop
  end
end
