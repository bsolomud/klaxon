require "test_helper"

class CarTransferTest < ActiveSupport::TestCase
  def setup
    @transfer = car_transfers(:pending_transfer)
  end

  # --- Enum ---

  test "status enum has correct values" do
    expected = { "requested" => 0, "approved" => 1, "rejected" => 2, "cancelled" => 3, "expired" => 4 }
    assert_equal expected, CarTransfer.statuses
  end

  test "defaults to requested status" do
    transfer = CarTransfer.new
    assert transfer.requested?
  end

  # --- Associations ---

  test "belongs to car" do
    assert_equal cars(:leaf), @transfer.car
  end

  test "belongs to from_user" do
    assert_equal users(:two), @transfer.from_user
  end

  test "belongs to to_user" do
    assert_equal users(:one), @transfer.to_user
  end

  # --- Token generation ---

  test "generates token on create" do
    transfer = CarTransfer.create!(
      car: cars(:camry),
      from_user: users(:one),
      to_user: users(:two)
    )
    assert transfer.token.present?
    assert transfer.token.length >= 32
  end

  test "does not overwrite existing token" do
    transfer = CarTransfer.new(
      car: cars(:camry),
      from_user: users(:one),
      to_user: users(:two),
      token: "custom-token-value"
    )
    transfer.save!
    assert_equal "custom-token-value", transfer.token
  end

  # --- Expires at ---

  test "sets expires_at to 14 days from now on create" do
    transfer = CarTransfer.create!(
      car: cars(:camry),
      from_user: users(:one),
      to_user: users(:two)
    )
    assert_in_delta 14.days.from_now, transfer.expires_at, 5.seconds
  end

  # --- expired? ---

  test "expired? returns true when expires_at is in the past" do
    @transfer.expires_at = 1.day.ago
    assert @transfer.expired?
  end

  test "expired? returns false when expires_at is in the future" do
    @transfer.expires_at = 1.day.from_now
    assert_not @transfer.expired?
  end

  # --- Token uniqueness ---

  test "token must be unique" do
    duplicate = CarTransfer.new(
      car: cars(:camry),
      from_user: users(:one),
      to_user: users(:two),
      token: @transfer.token
    )
    assert_not duplicate.valid?
    assert duplicate.errors[:token].any?
  end

  # --- Partial unique index (one active per car) ---

  test "cannot have two requested transfers for the same car" do
    assert @transfer.requested?
    duplicate = CarTransfer.new(
      car: @transfer.car,
      from_user: @transfer.from_user,
      to_user: users(:three),
      token: SecureRandom.urlsafe_base64(32),
      expires_at: 14.days.from_now
    )
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
  end

  test "can create new requested transfer after previous is approved" do
    approved = car_transfers(:approved_transfer)
    assert approved.approved?
    transfer = CarTransfer.create!(
      car: approved.car,
      from_user: approved.from_user,
      to_user: users(:one)
    )
    assert transfer.persisted?
  end

  # --- approve! ---

  test "approve! transfers car ownership in a transaction" do
    car = @transfer.car
    from_user = @transfer.from_user
    to_user = @transfer.to_user

    car.car_ownership_records.create!(user: from_user, started_at: 6.months.ago)

    @transfer.approve!(actor: from_user)

    @transfer.reload
    assert @transfer.approved?
    assert_equal to_user.id, car.reload.user_id

    old_record = car.car_ownership_records.find_by(user: from_user)
    assert_not_nil old_record.ended_at

    new_record = car.car_ownership_records.current.last
    assert_equal to_user.id, new_record.user_id
    assert_equal @transfer.id, new_record.car_transfer_id

    events = @transfer.car_transfer_events.order(:created_at)
    assert events.any?(&:approved?)
    assert events.any?(&:ownership_transferred?)
  end

  # --- reject! ---

  test "reject! changes status and creates event" do
    @transfer.reject!(actor: @transfer.from_user)

    assert @transfer.reload.rejected?
    event = @transfer.car_transfer_events.last
    assert event.rejected?
    assert_equal @transfer.from_user, event.actor
  end

  # --- cancel! ---

  test "cancel! changes status and creates event" do
    @transfer.cancel!(actor: @transfer.to_user)

    assert @transfer.reload.cancelled?
    event = @transfer.car_transfer_events.last
    assert event.cancelled?
    assert_equal @transfer.to_user, event.actor
  end

  # --- dependent: :restrict_with_exception ---

  test "cannot destroy transfer that has events" do
    assert @transfer.car_transfer_events.exists?
    assert_raises(ActiveRecord::DeleteRestrictionError) { @transfer.destroy! }
  end
end
