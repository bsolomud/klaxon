class ServiceCategory < ApplicationRecord
  has_many :workshop_service_categories, dependent: :destroy
  has_many :workshops, through: :workshop_service_categories

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end
