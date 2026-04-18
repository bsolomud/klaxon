class WorkshopManagement::QueueEntriesController < WorkshopManagement::BaseController
  include StateTransitionable
  include NotificationDispatch

  before_action :set_queue
  before_action :set_entry

  def call
    transition_queue_entry(
      :waiting,
      :called!,
      after_success: ->(entry) {
        dispatch_notification(
          recipients: entry.user,
          notifiable: entry,
          event: :queue_called,
          mailer: QueueMailer.with(queue_entry: entry).called
        )
      }
    ) do |entry|
      entry.called_at = Time.current
    end
    @entry.recompute_wait_estimates if @entry.called?
  end

  def serve
    transition_queue_entry(:called, :in_service!)
  end

  def complete
    transition_queue_entry(:in_service, :completed!) do |entry|
      entry.recompute_wait_estimates
    end
  end

  def no_show
    transition_queue_entry(:called, :no_show!) do |entry|
      entry.recompute_wait_estimates
    end
  end

  private

  def set_queue
    @queue = @workshop.service_queues.find(params[:queue_id])
  end

  def set_entry
    @entry = @queue.queue_entries.find(params[:id])
  end

  def transition_queue_entry(required_status, transition, after_success: nil, &block)
    transition_status(
      @entry,
      required_status: required_status,
      transition: transition,
      redirect_path: workshop_management_workshop_queue_path(@workshop, @queue),
      invalid_message: t("workshop_management.queue_entries.invalid_transition"),
      after_success: after_success,
      &block
    )
  end
end
