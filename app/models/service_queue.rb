class ServiceQueue < ApplicationRecord
  self.table_name = "queues"

  belongs_to :workshop
  belongs_to :service_category, optional: true

  has_many :queue_entries, foreign_key: :queue_id, dependent: :destroy

  enum :status, { open: 0, paused: 1, closed: 2 }

  STATUS_COLORS = {
    "open" => "green", "paused" => "yellow", "closed" => "gray"
  }.freeze

  validates :date, presence: true
  validates :workshop_id, uniqueness: { scope: [:service_category_id, :date] }

  scope :today, -> { where(date: Date.current) }

  def next_position
    queue_entries.maximum(:position).to_i + 1
  end

  def waiting_count
    queue_entries.waiting.count
  end

  def serving_count
    queue_entries.in_service.count
  end

  # Minutes each waiting driver represents, used for wait estimates. Reuses the
  # per-service duration the workshop configured; 30-minute default for the
  # general (category-less) queue or when the workshop set no duration.
  def entry_duration_minutes
    service_category
      &.workshop_service_categories
      &.find_by(workshop_id: workshop_id)
      &.estimated_duration_minutes || 30
  end

  def prospective_wait_minutes
    waiting_count * entry_duration_minutes
  end
end
