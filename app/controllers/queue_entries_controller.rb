class QueueEntriesController < ApplicationController
  def create
    @queue = ServiceQueue.open.find(params[:queue_id])

    # One active queue per driver, platform-wide: if they already have one,
    # send them to it instead of creating a second.
    if (existing = current_user.queue_entries.active.first)
      redirect_to queue_entry_path(existing), alert: t(".already_in_queue")
      return
    end

    # Resolve the car through the current user's own cars so a driver cannot
    # join a queue with (and leak) another driver's vehicle.
    car = current_user.cars.active.find_by(id: queue_entry_params[:car_id])

    @entry = @queue.queue_entries.new(
      user: current_user,
      car: car,
      joined_at: Time.current
    )

    ActiveRecord::Base.transaction do
      @entry.position = @queue.next_position
      @entry.save!
    end

    redirect_to queue_entry_path(@entry), notice: t(".success")
  rescue ActiveRecord::RecordNotUnique => e
    if e.message.include?("index_queue_entries_active_user")
      # Lost a race with another device that joined a queue first.
      existing = current_user.queue_entries.active.first
      redirect_to(existing ? queue_entry_path(existing) : workshop_path(@queue.workshop),
                  alert: t(".already_in_queue"))
    elsif e.message.include?("position")
      retry
    else
      raise
    end
  rescue ActiveRecord::RecordInvalid
    # A concurrent request may have created the driver's active entry between the
    # pre-flight check and save; route them to it with the same friendly message.
    if (existing = current_user.queue_entries.active.first)
      redirect_to queue_entry_path(existing), alert: t(".already_in_queue")
    else
      redirect_to workshop_path(@queue.workshop), alert: @entry.errors.full_messages.to_sentence
    end
  end

  def show
    @entry = current_user.queue_entries.find(params[:id])
    @queue = @entry.service_queue
  end

  def destroy
    # Only active entries can be left; a request to remove a completed/no-show
    # entry (not offered in the UI) 404s rather than deleting queue history.
    @entry = current_user.queue_entries.active.find(params[:id])
    workshop = @entry.service_queue.workshop
    @entry.destroy!
    redirect_to workshop_path(workshop), notice: t(".success")
  end

  private

  def queue_entry_params
    params.permit(:car_id)
  end
end
