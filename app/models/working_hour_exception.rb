# A one-off override of a workshop's weekly hours for a specific date — e.g. a
# public holiday or an unplanned closure. Presently only closures are modelled.
class WorkingHourException < ApplicationRecord
  belongs_to :workshop

  validates :date, presence: true, uniqueness: { scope: :workshop_id }

  scope :closures, -> { where(closed: true) }
  scope :upcoming, -> { where(date: Date.current..).order(:date) }
end
