require "test_helper"

class CarTransferMailerTest < ActionMailer::TestCase
  setup do
    @transfer = car_transfers(:pending_transfer)
    @from_user = @transfer.from_user
    @to_user = @transfer.to_user
    @car = @transfer.car
  end

  test "requested sends email to from_user with tokenized URL" do
    email = CarTransferMailer.with(transfer: @transfer).requested
    email.deliver_now

    assert_equal [@from_user.email], email.to
    assert_match @car.make, email.html_part.body.to_s
    assert_match @transfer.token, email.html_part.body.to_s
    assert_match @transfer.token, email.text_part.body.to_s
  end

  test "approved sends email to to_user (new owner)" do
    email = CarTransferMailer.with(transfer: @transfer).approved
    email.deliver_now

    assert_equal [@to_user.email], email.to
    assert_match @car.make, email.html_part.body.to_s
  end

  test "rejected sends email to to_user" do
    email = CarTransferMailer.with(transfer: @transfer).rejected
    email.deliver_now

    assert_equal [@to_user.email], email.to
    assert_match @car.make, email.html_part.body.to_s
  end

  test "cancelled sends email to from_user" do
    email = CarTransferMailer.with(transfer: @transfer).cancelled
    email.deliver_now

    assert_equal [@from_user.email], email.to
    assert_match @car.make, email.html_part.body.to_s
  end

  test "expired sends email to both parties" do
    email = CarTransferMailer.with(transfer: @transfer).expired
    email.deliver_now

    assert_includes email.to, @from_user.email
    assert_includes email.to, @to_user.email
    assert_equal 2, email.to.size
    assert_match @car.make, email.html_part.body.to_s
  end
end
