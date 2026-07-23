# A driver's grant that lets a specific workshop view this car's cross-workshop
# service history. Presence = access granted; destroying it revokes access.
class CarHistoryAccess < ApplicationRecord
  belongs_to :car
  belongs_to :workshop

  validates :car_id, uniqueness: { scope: :workshop_id }
end
