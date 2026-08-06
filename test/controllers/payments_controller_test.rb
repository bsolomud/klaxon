require "test_helper"

class PaymentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @sr = service_requests(:completed_request) # camry (user one), bill = 1700
    sign_in @user
  end

  test "create starts a payment and redirects to the gateway checkout" do
    assert_difference "Payment.count", 1 do
      post payments_path, params: { service_request_id: @sr.id }
    end
    payment = Payment.last
    assert_equal @sr, payment.payable
    assert_equal @user, payment.user
    assert_equal 1700, payment.amount.to_i
    assert payment.processing?
    assert_redirected_to payment_path(payment)
  end

  test "create rejects a request that is not payable" do
    @sr.payments.create!(user: @user, amount: 1700, currency: "UAH", status: :paid)
    assert_no_difference "Payment.count" do
      post payments_path, params: { service_request_id: @sr.id }
    end
    assert_redirected_to @sr
  end

  test "create cannot pay another user's request" do
    other = service_requests(:other_user_completed) # belongs to user two
    post payments_path, params: { service_request_id: other.id }
    assert_response :not_found
  end

  test "show renders the test gateway checkout" do
    post payments_path, params: { service_request_id: @sr.id }
    get payment_path(Payment.last)
    assert_response :success
  end

  test "callback with pay marks the payment paid and returns to the request" do
    post payments_path, params: { service_request_id: @sr.id }
    payment = Payment.last
    post payments_callback_path, params: { reference: payment.provider_reference, decision: "pay" }
    assert payment.reload.paid?
    assert @sr.reload.paid?
    assert_redirected_to @sr
  end

  test "callback with cancel marks the payment cancelled" do
    post payments_path, params: { service_request_id: @sr.id }
    payment = Payment.last
    post payments_callback_path, params: { reference: payment.provider_reference, decision: "cancel" }
    assert payment.reload.cancelled?
    assert_not @sr.reload.paid?
    assert_redirected_to @sr
  end

  test "create requires authentication" do
    sign_out @user
    post payments_path, params: { service_request_id: @sr.id }
    assert_redirected_to new_user_session_path
  end
end
