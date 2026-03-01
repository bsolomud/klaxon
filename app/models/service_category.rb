class ServiceCategory < ApplicationRecord
  has_many :workshops, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end
