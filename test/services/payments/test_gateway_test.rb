require "test_helper"

class Payments::TestGatewayTest < ActiveSupport::TestCase
  setup do
    @gateway = Payments::TestGateway.new
    @payment = service_requests(:completed_request).payments.create!(
      user: users(:one), amount: 1700, currency: "UAH"
    )
  end

  test "start marks the payment processing with a reference and checkout url" do
    checkout = @gateway.start(@payment)
    @payment.reload
    assert @payment.processing?
    assert_equal "test", @payment.provider
    assert @payment.provider_reference.present?
    assert_equal @payment.provider_reference, checkout.reference
    assert_equal "/payments/#{@payment.id}", checkout.redirect_url
  end

  test "verify_callback maps a pay decision to paid" do
    result = @gateway.verify_callback(reference: "abc", decision: "pay")
    assert_equal "abc", result.reference
    assert_equal :paid, result.status
  end

  test "verify_callback maps anything else to cancelled" do
    assert_equal :cancelled, @gateway.verify_callback(reference: "abc", decision: "cancel").status
  end

  test "refund returns true" do
    assert @gateway.refund(@payment)
  end
end
