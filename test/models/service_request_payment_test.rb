require "test_helper"

class ServiceRequestPaymentTest < ActiveSupport::TestCase
  setup do
    @request = service_requests(:completed_request) # completed, record bill = 1700
    @user = users(:one)
  end

  test "outstanding_amount is the service record total" do
    assert_equal 1700, @request.outstanding_amount.to_i
  end

  test "payable when completed with an unpaid bill" do
    assert @request.payable?
    assert_not @request.paid?
  end

  test "not payable once a successful payment exists" do
    @request.payments.create!(user: @user, amount: 1700, currency: "UAH", status: :paid)
    assert @request.paid?
    assert_not @request.payable?
  end

  test "a pending payment does not count as paid" do
    @request.payments.create!(user: @user, amount: 1700, currency: "UAH", status: :pending)
    assert_not @request.paid?
    assert @request.payable?
  end

  test "not payable without a bill" do
    request = service_requests(:other_user_completed) # completed, no service record
    assert_equal 0, request.outstanding_amount.to_i
    assert_not request.payable?
  end

  test "not payable until completed" do
    assert_not service_requests(:pending_request).payable?
  end
end
