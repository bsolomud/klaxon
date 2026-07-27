require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @request = service_requests(:completed_request)
  end

  test "valid with amount, currency, user, and payable" do
    payment = @request.payments.build(user: @user, amount: 1700, currency: "UAH")
    assert payment.valid?
  end

  test "requires a positive amount" do
    assert_not @request.payments.build(user: @user, amount: 0, currency: "UAH").valid?
    assert_not @request.payments.build(user: @user, amount: -5, currency: "UAH").valid?
  end

  test "requires a currency" do
    assert_not @request.payments.build(user: @user, amount: 100, currency: nil).valid?
  end

  test "mark_paid! sets status and paid_at" do
    payment = @request.payments.create!(user: @user, amount: 1700, currency: "UAH")
    payment.mark_paid!
    assert payment.paid?
    assert_not_nil payment.paid_at
  end

  test "successful scope returns only paid payments" do
    paid = @request.payments.create!(user: @user, amount: 1700, currency: "UAH", status: :paid)
    pending = @request.payments.create!(user: @user, amount: 1700, currency: "UAH", status: :pending)
    assert_includes Payment.successful, paid
    assert_not_includes Payment.successful, pending
  end

  test "finalized? is true for terminal statuses" do
    assert @request.payments.build(status: :paid).finalized?
    assert @request.payments.build(status: :cancelled).finalized?
    assert_not @request.payments.build(status: :processing).finalized?
  end
end
