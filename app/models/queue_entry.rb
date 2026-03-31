class QueueEntry < ApplicationRecord
  belongs_to :service_queue, foreign_key: :queue_id
  belongs_to :user
  belongs_to :car, optional: true

  enum :status, { waiting: 0, called: 1, in_service: 2, completed: 3, no_show: 4 }

  validates :position, presence: true,
            uniqueness: { scope: :queue_id }
  validates :joined_at, presence: true
  validates :queue_id, uniqueness: {
    scope: :user_id,
    conditions: -> { where(status: [:waiting, :called, :in_service]) },
    message: :already_in_queue
  }

  scope :active, -> { where(status: [:waiting, :called, :in_service]) }

  after_create :recompute_wait_estimates
  after_update_commit :broadcast_queue_update, if: :saved_change_to_status?

  def recompute_wait_estimates
    queue = service_queue
    duration = queue.service_category
                    &.workshop_service_categories
                    &.find_by(workshop_id: queue.workshop_id)
                    &.estimated_duration_minutes || 30

    waiting_entries = queue.queue_entries.waiting.order(:position).pluck(:id)
    waiting_entries.each_with_index do |entry_id, index|
      QueueEntry.where(id: entry_id).update_all(estimated_wait_minutes: index * duration)
    end
  end

  private

  def broadcast_queue_update
    broadcast_replace_to(
      "queue_#{queue_id}",
      target: ActionView::RecordIdentifier.dom_id(self),
      partial: "queue_entries/queue_entry",
      locals: { entry: self }
    )
  end
end
