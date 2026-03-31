class QueueEntriesController < ApplicationController
  def create
    @queue = ServiceQueue.open.find(params[:queue_id])

    @entry = @queue.queue_entries.new(
      user: current_user,
      car_id: queue_entry_params[:car_id],
      joined_at: Time.current
    )

    ActiveRecord::Base.transaction do
      @entry.position = @queue.next_position
      @entry.save!
    end

    redirect_to queue_entry_path(@entry), notice: t(".success")
  rescue ActiveRecord::RecordNotUnique
    retry
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
