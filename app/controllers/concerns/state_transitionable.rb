module StateTransitionable
  extend ActiveSupport::Concern

  private

  def transition_status(record, transition:, redirect_path:, required_status: nil, invalid_message: nil, after_success: nil)
    if required_status && record.status != required_status.to_s
      redirect_to redirect_path, alert: invalid_message
      return
    end

    record.lock_version = params[:lock_version].to_i
    yield record if block_given?
    record.send(transition)
    after_success&.call(record)
    redirect_to redirect_path, notice: t(".success")
  rescue ActiveRecord::StaleObjectError
    redirect_to redirect_path, alert: t(".stale")
  end
end
