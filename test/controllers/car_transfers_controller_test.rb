require "test_helper"

class CarTransfersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @other_user = users(:two)
    @car_with_vin = cars(:leaf) # belongs to @other_user, has VIN
    @transfer = car_transfers(:pending_transfer)
    sign_in @user
  end

  # --- New ---

  test "new renders transfer form for car with VIN belonging to another user" do
    get new_car_transfer_path(vin: @car_with_vin.vin)
    assert_response :success
    assert_select "h1", text: I18n.t("car_transfers.new.title")
  end

  test "new redirects if VIN belongs to current user" do
    own_car = cars(:camry)
    get new_car_transfer_path(vin: own_car.vin)
    assert_redirected_to cars_path
    assert_equal I18n.t("car_transfers.new.own_car"), flash[:alert]
  end

  test "new returns 404 for non-existent VIN" do
    get new_car_transfer_path(vin: "NONEXISTENT1234567")
    assert_response :not_found
  end

  test "new requires authentication" do
    sign_out @user
    get new_car_transfer_path(vin: @car_with_vin.vin)
    assert_redirected_to new_user_session_path
  end

  # --- Create ---

  test "create initiates transfer and creates event" do
    @transfer.cancelled!

    assert_difference ["CarTransfer.count", "CarTransferEvent.count"], 1 do
      post car_transfers_path, params: { car_transfer: { vin: @car_with_vin.vin } }
    end

    transfer = CarTransfer.last
    assert transfer.requested?
    assert_equal @car_with_vin, transfer.car
    assert_equal @other_user, transfer.from_user
    assert_equal @user, transfer.to_user
    assert transfer.token.present?
    assert_in_delta 14.days.from_now, transfer.expires_at, 5.seconds

    event = CarTransferEvent.last
    assert event.transfer_requested?
    assert_equal @user, event.actor

    assert_redirected_to car_transfer_path(transfer)
  end

  test "create prevents transferring own car" do
    own_car = cars(:camry)
    assert_no_difference "CarTransfer.count" do
      post car_transfers_path, params: { car_transfer: { vin: own_car.vin } }
    end
    assert_redirected_to cars_path
    assert_equal I18n.t("car_transfers.new.own_car"), flash[:alert]
  end

  test "create prevents duplicate active transfer" do
    assert @transfer.requested?
    assert_equal @car_with_vin, @transfer.car

    assert_no_difference "CarTransfer.count" do
      post car_transfers_path, params: { car_transfer: { vin: @car_with_vin.vin } }
    end
    assert_redirected_to cars_path
    assert_equal I18n.t("car_transfers.create.already_active"), flash[:alert]
  end

  test "create requires authentication" do
    sign_out @user
    post car_transfers_path, params: { car_transfer: { vin: @car_with_vin.vin } }
    assert_redirected_to new_user_session_path
  end

  # --- Show ---

  test "show displays transfer details" do
    get car_transfer_path(token: @transfer.token)
    assert_response :success
    assert_select "h1", text: I18n.t("car_transfers.show.title")
  end

  test "show returns 404 for invalid token" do
    get car_transfer_path(token: "invalid-token")
    assert_response :not_found
  end

  test "show requires authentication" do
    sign_out @user
    get car_transfer_path(token: @transfer.token)
    assert_redirected_to new_user_session_path
  end

  test "show displays approve and reject buttons for from_user" do
    sign_in @other_user # from_user
    get car_transfer_path(token: @transfer.token)
    assert_select "form[action=?]", approve_car_transfer_path(token: @transfer.token)
    assert_select "form[action=?]", reject_car_transfer_path(token: @transfer.token)
  end

  test "show displays cancel button for to_user" do
    get car_transfer_path(token: @transfer.token) # @user is to_user
    assert_select "form[action=?]", cancel_car_transfer_path(token: @transfer.token)
  end

  test "show hides action buttons for non-requested transfer" do
    @transfer.update_column(:status, CarTransfer.statuses[:rejected])
    get car_transfer_path(token: @transfer.token)
    assert_select "form[action=?]", approve_car_transfer_path(token: @transfer.token), count: 0
    assert_select "form[action=?]", cancel_car_transfer_path(token: @transfer.token), count: 0
  end

  # --- Approve ---

  test "approve transfers car ownership" do
    sign_in @other_user # from_user

    @car_with_vin.car_ownership_records.create!(user: @other_user, started_at: 6.months.ago)

    assert_difference "CarOwnershipRecord.count", 1 do
      patch approve_car_transfer_path(token: @transfer.token)
    end

    @transfer.reload
    assert @transfer.approved?
    assert_equal @user.id, @car_with_vin.reload.user_id

    assert_redirected_to car_transfer_path(token: @transfer.token)
    assert_equal I18n.t("car_transfers.approve.success"), flash[:notice]
  end

  test "approve rejects non-from_user" do
    patch approve_car_transfer_path(token: @transfer.token)
    assert_redirected_to car_transfer_path(token: @transfer.token)
    assert_equal I18n.t("car_transfers.approve.not_authorized"), flash[:alert]
    assert @transfer.reload.requested?
  end

  test "approve rejects expired transfer" do
    sign_in @other_user
    @transfer.update_column(:expires_at, 1.day.ago)

    patch approve_car_transfer_path(token: @transfer.token)
    assert_redirected_to car_transfer_path(token: @transfer.token)
    assert_equal I18n.t("car_transfers.approve.expired"), flash[:alert]
    assert @transfer.reload.requested?
  end

  test "approve returns 404 for non-requested transfer" do
    sign_in @other_user
    @transfer.update_column(:status, CarTransfer.statuses[:rejected])

    patch approve_car_transfer_path(token: @transfer.token)
    assert_response :not_found
  end

  # --- Reject ---

  test "reject changes status and creates event" do
    sign_in @other_user # from_user

    assert_difference "CarTransferEvent.count", 1 do
      patch reject_car_transfer_path(token: @transfer.token)
    end

    assert @transfer.reload.rejected?
    assert_redirected_to car_transfer_path(token: @transfer.token)
    assert_equal I18n.t("car_transfers.reject.success"), flash[:notice]
  end

  test "reject denies non-from_user" do
    patch reject_car_transfer_path(token: @transfer.token)
    assert_redirected_to car_transfer_path(token: @transfer.token)
    assert_equal I18n.t("car_transfers.reject.not_authorized"), flash[:alert]
    assert @transfer.reload.requested?
  end

  test "reject returns 404 for non-requested transfer" do
    sign_in @other_user
    @transfer.update_column(:status, CarTransfer.statuses[:cancelled])

    patch reject_car_transfer_path(token: @transfer.token)
    assert_response :not_found
  end

  # --- Cancel ---

  test "cancel changes status and creates event" do
    assert_difference "CarTransferEvent.count", 1 do
      patch cancel_car_transfer_path(token: @transfer.token)
    end

    assert @transfer.reload.cancelled?
    assert_redirected_to car_transfer_path(token: @transfer.token)
    assert_equal I18n.t("car_transfers.cancel.success"), flash[:notice]
  end

  test "cancel denies non-to_user" do
    sign_in @other_user # from_user, not to_user
    patch cancel_car_transfer_path(token: @transfer.token)
    assert_redirected_to car_transfer_path(token: @transfer.token)
    assert_equal I18n.t("car_transfers.cancel.not_authorized"), flash[:alert]
    assert @transfer.reload.requested?
  end

  test "cancel returns 404 for non-requested transfer" do
    @transfer.update_column(:status, CarTransfer.statuses[:approved])

    patch cancel_car_transfer_path(token: @transfer.token)
    assert_response :not_found
  end
end
