require "test_helper"

class CarTransferEventTest < ActiveSupport::TestCase
  def setup
    @event = car_transfer_events(:pending_transfer_requested)
  end

  # --- Enum ---

  test "event_type enum has correct values" do
    expected = {
      "transfer_requested" => 0, "notification_sent" => 1,
      "approved" => 2, "rejected" => 3, "cancelled" => 4,
      "expired" => 5, "ownership_transferred" => 6
    }
    assert_equal expected, CarTransferEvent.event_types
  end

  # --- Associations ---

  test "belongs to car_transfer" do
    assert_equal car_transfers(:pending_transfer), @event.car_transfer
  end

  test "belongs to actor" do
    assert_equal users(:one), @event.actor
  end

  test "actor is optional" do
    event = CarTransferEvent.create!(
      car_transfer: car_transfers(:pending_transfer),
      event_type: :expired,
      actor: nil
    )
    assert_nil event.actor
  end

  # --- No updated_at ---

  test "table has no updated_at column" do
    assert_not CarTransferEvent.column_names.include?("updated_at")
  end

  # --- Append-only ---

  test "cannot update persisted record" do
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      @event.update!(event_type: :approved)
    end
  end

  test "cannot destroy record" do
    assert_not @event.destroy
    assert @event.persisted?
  end

  # --- Validations ---

  test "event_type is required" do
    event = CarTransferEvent.new(car_transfer: car_transfers(:pending_transfer))
    assert_not event.valid?
    assert event.errors[:event_type].any?
  end
end
