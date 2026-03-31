class WorkshopManagement::QueueEntriesController < WorkshopManagement::BaseController
  before_action :set_queue
  before_action :set_entry

  def call
    transition_entry(:waiting, :called!) do
      @entry.called_at = Time.current
    end
  end

  def serve
    transition_entry(:called, :in_service!)
  end

  def complete
    transition_entry(:in_service, :completed!) do
      @entry.recompute_wait_estimates
    end
  end

  def no_show
    transition_entry(:called, :no_show!) do
      @entry.recompute_wait_estimates
    end
  end

  private

  def set_queue
    @queue = @workshop.service_queues.find(params[:queue_id])
  end

  def set_entry
    @entry = @queue.queue_entries.find(params[:id])
  end

  def transition_entry(required_status, transition_method)
    unless @entry.status == required_status.to_s
      redirect_to workshop_management_workshop_queue_path(@workshop, @queue),
                  alert: t("workshop_management.queue_entries.invalid_transition")
      return
    end

    @entry.lock_version = params[:lock_version].to_i
    yield if block_given?
    @entry.send(transition_method)
    @entry.recompute_wait_estimates if transition_method == :called!
    redirect_to workshop_management_workshop_queue_path(@workshop, @queue),
                notice: t(".success")
  rescue ActiveRecord::StaleObjectError
    redirect_to workshop_management_workshop_queue_path(@workshop, @queue),
                alert: t(".stale")
  end
end
