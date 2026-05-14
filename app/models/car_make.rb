class CarMake < ApplicationRecord
  has_many :car_models, dependent: :destroy
  has_many :cars
  belongs_to :submitted_by, class_name: "User", optional: true

  enum :status, { pending: 0, approved: 1, rejected: 2 }

  STATUS_COLORS = {
    "pending" => "yellow",
    "approved" => "green",
    "rejected" => "red"
  }.freeze

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  normalizes :name, with: ->(v) { v&.strip }

  scope :approved, -> { where(status: :approved) }
end
