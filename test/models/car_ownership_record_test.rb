require "test_helper"

class CarOwnershipRecordTest < ActiveSupport::TestCase
  def setup
    @record = car_ownership_records(:camry_ownership)
  end

  # --- Associations ---

  test "belongs to car" do
    assert_equal cars(:camry), @record.car
  end

  test "belongs to user" do
    assert_equal users(:one), @record.user
  end

  test "car_transfer is optional" do
    assert_nil @record.car_transfer
    assert @record.valid?
  end

  # --- Validations ---

  test "started_at is required" do
    @record.started_at = nil
    assert_not @record.valid?
    assert @record.errors[:started_at].any?
  end

  # --- No updated_at ---

  test "table has no updated_at column" do
    assert_not CarOwnershipRecord.column_names.include?("updated_at")
  end

  # --- current scope ---

  test "current scope returns records with nil ended_at" do
    records = CarOwnershipRecord.current
    records.each do |record|
      assert_nil record.ended_at
    end
  end

  # --- ended_at nil means current owner ---

  test "ended_at nil means current owner" do
    assert_nil @record.ended_at
  end

  # --- Append-only for historical records ---

  test "cannot update record once ended_at is set" do
    @record.update_column(:ended_at, 1.day.ago)
    @record.reload
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      @record.update!(started_at: Time.current)
    end
  end

  test "can update ended_at on current record" do
    assert_nil @record.ended_at
    @record.update!(ended_at: Time.current)
    assert_not_nil @record.reload.ended_at
  end
end
