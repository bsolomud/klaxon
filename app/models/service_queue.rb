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
end
