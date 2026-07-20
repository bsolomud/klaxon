class QueueEntry < ApplicationRecord
  belongs_to :service_queue, foreign_key: :queue_id
  belongs_to :user
  belongs_to :car, optional: true

  enum :status, { waiting: 0, called: 1, in_service: 2, completed: 3, no_show: 4 }

  STATUS_COLORS = {
    "waiting" => "yellow", "called" => "blue", "in_service" => "indigo",
    "completed" => "green", "no_show" => "red"
  }.freeze

  validates :position, presence: true,
            uniqueness: { scope: :queue_id }
  validates :joined_at, presence: true
  # One active entry per user across ALL queues (platform-wide). Rails excludes
  # the current record on update, so operator status transitions still validate.
  validates :user_id, uniqueness: {
    conditions: -> { where(status: [:waiting, :called, :in_service]) },
    message: :already_in_queue
  }

  scope :active, -> { where(status: [:waiting, :called, :in_service]) }

  after_create :recompute_wait_estimates
  after_create_commit :broadcast_entry_created
  after_update_commit :broadcast_entry_updated, if: :saved_change_to_status?
  after_update_commit :refresh_siblings_after_status_change, if: :saved_change_to_status?
  after_destroy_commit :refresh_siblings_after_leave
  after_destroy_commit :broadcast_entry_removed

  # Capacity-aware wait estimate. A waiting entry that has a free bay available
  # right now waits ~0 min ("go now"); otherwise it waits for the jobs ahead of
  # it to clear across the available bays, including anyone currently in service.
  def recompute_wait_estimates
    queue = service_queue
    return if queue.nil? # queue was destroyed (cascade); nothing to recompute

    duration = queue.entry_duration_minutes
    bays = [queue.concurrency, 1].max
    free = [bays - queue.serving_count, 0].max

    queue.queue_entries.waiting.order(:position).each_with_index do |entry, i|
      wait = i < free ? 0 : (((i - free) / bays) + 1) * duration
      entry.update_column(:estimated_wait_minutes, wait) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  private

  # after_*_commit callbacks are keyed by method name, so the update and destroy
  # variants must use distinct method names or one silently overrides the other.
  def refresh_siblings_after_status_change
    refresh_sibling_estimates
  end

  def refresh_siblings_after_leave
    refresh_sibling_estimates
  end

  def refresh_sibling_estimates
    return if service_queue.nil? # queue was destroyed (cascade)

    recompute_wait_estimates
    broadcast_sibling_wait_estimates
  end

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
