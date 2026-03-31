class WorkshopManagement::QueuesController < WorkshopManagement::BaseController
  before_action :set_queue, only: [:show, :pause, :close]

  def index
    @queues = @workshop.service_queues.today.includes(:service_category)
  end

  def show
    @entries = @queue.queue_entries.includes(:user, :car).order(:position)
  end

  def open
    @queue = @workshop.service_queues.find_by(
      date: Date.current,
      service_category_id: params[:service_category_id]
    )

    if @queue.nil?
      @queue = @workshop.service_queues.create!(
        date: Date.current,
        service_category_id: params[:service_category_id],
        status: :open
      )
    elsif @queue.paused?
      @queue.open!
    end

    redirect_to workshop_management_workshop_queue_path(@workshop, @queue),
                notice: t(".success")
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

    @queue.closed!
    redirect_to workshop_management_workshop_queue_path(@workshop, @queue),
                notice: t(".success")
  end

  private

  def set_queue
    @queue = @workshop.service_queues.find(params[:id])
  end
end
