class WorkshopOperator < ApplicationRecord
  belongs_to :user
  belongs_to :workshop

  enum :role, { owner: 0, staff: 1 }

  validates :user_id, uniqueness: { scope: :workshop_id }
end
