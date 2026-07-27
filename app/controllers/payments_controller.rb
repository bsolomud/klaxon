class PaymentsController < ApplicationController
  # Start paying the final bill for one of the current driver's completed jobs.
  def create
    service_request = current_user_service_requests.find(params[:service_request_id])
    unless service_request.payable?
      redirect_to service_request, alert: t(".unavailable")
      return
    end

    record = service_request.service_record
    payment = service_request.payments.create!(
      user: current_user, amount: record.total_cost, currency: record.currency
    )
    checkout = Payments.gateway.start(payment)
    redirect_to checkout.redirect_url, allow_other_host: true
  end

  def show
    @payment = current_user.payments.find(params[:id])
  end

  # Gateway confirmation. With the TestGateway this is the Pay/Cancel button on
  # the checkout page; a real provider would POST its webhook to an equivalent
  # (unauthenticated) endpoint. Lookup is scoped to the payer's own payments.
  def callback
    result = Payments.gateway.verify_callback(params)
    payment = current_user.payments.find_by!(provider_reference: result.reference)

    if result.status == :paid
      payment.mark_paid!
      redirect_to payment.payable, notice: t(".paid")
    else
      payment.cancelled!
      redirect_to payment.payable, alert: t(".cancelled")
    end
  end

  private

  def current_user_service_requests
    ServiceRequest.where(car: current_user.cars)
  end
end
