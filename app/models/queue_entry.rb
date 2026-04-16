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
  after_create_commit :broadcast_entry_created
  after_update_commit :broadcast_entry_updated, if: :saved_change_to_status?
  after_update_commit :broadcast_sibling_wait_estimates, if: :saved_change_to_status?
  after_destroy_commit :broadcast_entry_removed

  def recompute_wait_estimates
    queue = service_queue
    duration = queue.service_category
                    &.workshop_service_categories
                    &.find_by(workshop_id: queue.workshop_id)
                    &.estimated_duration_minutes || 30

    waiting_ids = queue.queue_entries.waiting.order(:position).pluck(:id)
    return if waiting_ids.empty?

    cases = waiting_ids.each_with_index.map { |id, i| "WHEN #{id} THEN #{i * duration}" }
    queue.queue_entries.where(id: waiting_ids).update_all(
      "estimated_wait_minutes = CASE id #{cases.join(' ')} END"
    )
  end

  private

  def broadcast_entry_created
    broadcast_append_to(
      "queue_#{queue_id}_drivers",
      target: "queue_entries",
      partial: "queue_entries/queue_entry",
      locals: { entry: self }
    )
    broadcast_append_to(
      "queue_#{queue_id}_operators",
      target: "operator_queue_entries",
      partial: "workshop_management/queue_entries/queue_entry",
      locals: { entry: self }
    )
  end

  def broadcast_entry_updated
    broadcast_replace_to(
      "queue_#{queue_id}_drivers",
      target: ActionView::RecordIdentifier.dom_id(self),
      partial: "queue_entries/queue_entry",
      locals: { entry: self }
    )
    broadcast_replace_to(
      "queue_#{queue_id}_operators",
      target: ActionView::RecordIdentifier.dom_id(self, :operator),
      partial: "workshop_management/queue_entries/queue_entry",
      locals: { entry: self }
    )
  end

  def broadcast_entry_removed
    broadcast_remove_to("queue_#{queue_id}_drivers", target: ActionView::RecordIdentifier.dom_id(self))
    broadcast_remove_to("queue_#{queue_id}_operators", target: ActionView::RecordIdentifier.dom_id(self, :operator))
  end

  def broadcast_sibling_wait_estimates
    service_queue.queue_entries.waiting.where.not(id: id).find_each do |entry|
      entry.broadcast_replace_to(
        "queue_#{queue_id}_drivers",
        target: ActionView::RecordIdentifier.dom_id(entry),
        partial: "queue_entries/queue_entry",
        locals: { entry: entry }
      )
      entry.broadcast_replace_to(
        "queue_#{queue_id}_operators",
        target: ActionView::RecordIdentifier.dom_id(entry, :operator),
        partial: "workshop_management/queue_entries/queue_entry",
        locals: { entry: entry }
      )
    end
  end
end
