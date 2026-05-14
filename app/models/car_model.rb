class CarModel < ApplicationRecord
  belongs_to :car_make
  has_many :cars
  belongs_to :submitted_by, class_name: "User", optional: true

  enum :status, { pending: 0, approved: 1, rejected: 2 }

  validates :name, presence: true, uniqueness: { scope: :car_make_id, case_sensitive: false }

  normalizes :name, with: ->(v) { v&.strip }

  scope :approved, -> { where(status: :approved) }
end
