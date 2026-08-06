class WorkshopManagement::QueuesController < WorkshopManagement::BaseController
  include NotificationDispatch

  before_action :set_queue, only: [:show, :pause, :close]

  def index
    @queues_by_category = @workshop.service_queues.today.index_by(&:service_category_id)
    @service_categories = @workshop.service_categories.order(:name)
  end

  def show
    @entries = @queue.queue_entries.includes(:user, :car).order(:position)
  end

  def open
    category_id = params[:service_category_id].presence

    if category_id && !@workshop.service_category_ids.include?(category_id.to_i)
      redirect_to workshop_management_workshop_queues_path(@workshop),
                  alert: t("workshop_management.queues.invalid_category")
      return
    end

    @queue = @workshop.service_queues.find_or_create_by!(
      date: Date.current,
      service_category_id: category_id
    ) { |queue| queue.status = :open }

    @queue.open! if @queue.paused?

    redirect_to workshop_management_workshop_queue_path(@workshop, @queue),
                notice: t(".success")
  rescue ActiveRecord::RecordNotUnique
    # Lost the create race (unique index on workshop/category/date, including the
    # partial index for nil categories) — re-run and find the winning queue.
    retry
  end

  def pause
    unless @queue.open?
      redirect_to workshop_management_workshop_queue_path(@workshop, @queue),
                  alert: t("workshop_management.queues.invalid_transition")
      return
    end

    @queue.paused!
    redirect_to workshop_management_workshop_queue_path(@workshop, @queue),
                notice: t(".success")
  end

  def close
    unless @queue.open? || @queue.paused?
      redirect_to workshop_management_workshop_queue_path(@workshop, @queue),
                  alert: t("workshop_management.queues.invalid_transition")
      return
    end

    cancelled = cancel_pending_entries
    @queue.closed!
    notify_cancelled(cancelled)

    redirect_to workshop_management_workshop_queue_path(@workshop, @queue),
                notice: t(".success")
  end

  private

  def set_queue
    @queue = @workshop.service_queues.find(params[:id])
  end

  # Closing a queue must not strand the drivers waiting in it: cancel the
  # still-open entries and notify each so they can make other plans.
  def cancel_pending_entries
    @queue.queue_entries.where(status: [:waiting, :called]).to_a.each(&:cancelled!)
  end

  def notify_cancelled(entries)
    entries.each do |entry|
      dispatch_notification(recipients: entry.user_id, notifiable: entry, event: :queue_cancelled)
    end
  end
end
