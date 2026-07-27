# Payment gateway abstraction. Every adapter implements the same three methods:
#
#   start(payment)          -> Payments::Checkout(redirect_url:, reference:)
#   verify_callback(params) -> Payments::CallbackResult(reference:, status:)
#   refund(payment)         -> truthy on success
#
# The default TestGateway needs no credentials and drives the whole UX locally.
# To go live, set `Payments.gateway = Payments::LiqpayGateway.new(...)` (or any
# real adapter) in an initializer — nothing else changes.
module Payments
  Checkout = Data.define(:redirect_url, :reference)
  CallbackResult = Data.define(:reference, :status)

  class << self
    attr_writer :gateway

    def gateway
      @gateway ||= TestGateway.new
    end
  end
end
