class WorkingHour < ApplicationRecord
  belongs_to :workshop

  validates :day_of_week, inclusion: { in: 0..6 },
                         uniqueness: { scope: :workshop_id }
  validates :opens_at, presence: true, unless: :closed?
  validates :closes_at, presence: true, unless: :closed?
end
