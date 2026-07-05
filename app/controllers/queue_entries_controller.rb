class QueueEntriesController < ApplicationController
  def create
    @queue = ServiceQueue.open.find(params[:queue_id])
    # Resolve the car through the current user's own cars so a driver cannot
    # join a queue with (and leak) another driver's vehicle.
    car = current_user.cars.find_by(id: queue_entry_params[:car_id])

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
    if e.message.include?("index_queue_entries_active_user_per_queue")
      redirect_to workshop_path(@queue.workshop), alert: t(".already_in_queue")
    elsif e.message.include?("position")
      retry
    else
      raise
    end
  rescue ActiveRecord::RecordInvalid
    redirect_to workshop_path(@queue.workshop), alert: @entry.errors.full_messages.to_sentence
  end

  def show
    @entry = current_user.queue_entries.find(params[:id])
    @queue = @entry.service_queue
  end

  private

  def queue_entry_params
    params.permit(:car_id)
  end
end
