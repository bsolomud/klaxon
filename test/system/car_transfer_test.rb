require "application_system_test_case"

class CarTransferTest < ApplicationSystemTestCase
  include ActionMailer::TestHelper
  include ActiveJob::TestHelper

  def setup
    @user_a = users(:one) # current owner of camry
    @user_b = users(:driver_no_workshops)
    @car = cars(:camry) # owned by user_a, VIN: 1HGBH41JXMN109186
  end

  test "full car transfer flow: request, approve, ownership changes" do
    assert_equal @user_a.id, @car.user_id

    # User B signs in and tries to add a car with the same VIN
    using_session(:user_b) do
      sign_in_user(@user_b)

      visit new_car_path
      fill_in "car_make", with: "Toyota"
      fill_in "car_model", with: "Camry"
      fill_in "car_year", with: "2020"
      fill_in "car_license_plate", with: "XX1234YY"
      fill_in "car_vin", with: @car.vin
      find("#car_fuel_type").select(I18n.t("cars.fuel_types.gasoline"))
      find('input[type="submit"]').click

      # VIN uniqueness error shown
      assert_text I18n.t("cars.form.vin_duplicate_title")

      # User B navigates to transfer request page
      visit new_car_transfer_path(vin: @car.vin)
      assert_text @car.make
      assert_text @car.vin

      # CarTransferMailer#requested is enqueued for deliver_later. Flush the
      # job queue so the email actually lands — the transfer flow is dead
      # without this email, per Phase 14 / Task 84.
      assert_emails 1 do
        perform_enqueued_jobs do
          click_button I18n.t("car_transfers.new.submit")
          assert_text I18n.t("car_transfers.create.success")
        end
      end

      # The request email was delivered to user A (from_user).
      request_email = ActionMailer::Base.deliveries.last
      assert_includes request_email.to, @user_a.email
    end

    # Verify transfer was created with a token
    transfer = CarTransfer.find_by!(car: @car, to_user: @user_b, from_user: @user_a)
    assert transfer.requested?
    assert transfer.token.present?

    # Verify transfer event was created
    assert transfer.car_transfer_events.exists?(event_type: :transfer_requested)

    # User A signs in and follows the token link to approve
    using_session(:user_a) do
      sign_in_user(@user_a)

      visit car_transfer_path(token: transfer.token)
      assert_text @car.display_name
      assert_text I18n.t("car_transfers.statuses.requested")

      click_button I18n.t("car_transfers.show.approve")
      assert_text I18n.t("car_transfers.approve.success")
    end

    # Verify final state
    @car.reload
    transfer.reload

    assert_equal @user_b.id, @car.user_id, "Car should now belong to user B"
    assert transfer.approved?, "Transfer should be approved"

    # Verify audit trail
    assert transfer.car_transfer_events.exists?(event_type: :approved)
    assert transfer.car_transfer_events.exists?(event_type: :ownership_transferred)

    # Verify ownership records
    old_record = @car.car_ownership_records.find_by(user: @user_a)
    assert old_record.ended_at.present?, "Old ownership record should be closed"

    new_record = @car.car_ownership_records.find_by(user: @user_b)
    assert new_record.present?, "New ownership record should exist"
    assert_nil new_record.ended_at, "New ownership record should be current"
    assert_equal transfer.id, new_record.car_transfer_id
  end
end
