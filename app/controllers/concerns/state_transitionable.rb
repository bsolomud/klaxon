module StateTransitionable
  extend ActiveSupport::Concern

  private

  def transition_status(record, required_status:, transition:, redirect_path:, invalid_message:, after_success: nil)
    unless record.status == required_status.to_s
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
