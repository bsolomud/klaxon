require "test_helper"

class ExpireCarTransfersJobTest < ActiveSupport::TestCase
  def setup
    @transfer = car_transfers(:pending_transfer)
  end

  test "expires transfers past expires_at" do
    @transfer.update_column(:expires_at, 1.day.ago)

    assert_difference "CarTransferEvent.count", 1 do
      ExpireCarTransfersJob.perform_now
    end

    @transfer.reload
    assert @transfer.expired?

    event = @transfer.car_transfer_events.last
    assert event.expired?
    assert_nil event.actor
  end

  test "does not expire transfers with future expires_at" do
    assert @transfer.expires_at > Time.current

    assert_no_difference "CarTransferEvent.count" do
      ExpireCarTransfersJob.perform_now
    end

    assert @transfer.reload.requested?
  end

  test "does not expire non-requested transfers" do
    @transfer.update_columns(status: CarTransfer.statuses[:approved], expires_at: 1.day.ago)

    assert_no_difference "CarTransferEvent.count" do
      ExpireCarTransfersJob.perform_now
    end

    assert @transfer.reload.approved?
  end

  test "expires multiple transfers in one run" do
    # Create a second expired transfer
    transfer2 = CarTransfer.create!(
      car: cars(:camry),
      from_user: users(:one),
      to_user: users(:three)
    )
    @transfer.update_column(:expires_at, 1.hour.ago)
    transfer2.update_column(:expires_at, 2.hours.ago)

    assert_difference "CarTransferEvent.count", 2 do
      ExpireCarTransfersJob.perform_now
    end

    assert @transfer.reload.expired?
    assert transfer2.reload.expired?
  end
end
