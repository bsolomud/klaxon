module Payments
  # A self-contained gateway that needs no credentials: "checkout" is an in-app
  # page with Pay / Cancel buttons that post back to our own callback. Lets the
  # full payment flow run in development, demos, and tests with no real provider.
  class TestGateway
    def start(payment)
      reference = "test_#{SecureRandom.hex(8)}"
      payment.update!(provider: "test", provider_reference: reference, status: :processing)
      Payments::Checkout.new(
        redirect_url: Rails.application.routes.url_helpers.payment_path(payment),
        reference: reference
      )
    end

    def verify_callback(params)
      status = params[:decision] == "pay" ? :paid : :cancelled
      Payments::CallbackResult.new(reference: params[:reference].to_s, status: status)
    end

    def refund(_payment)
      true
    end
  end
end
