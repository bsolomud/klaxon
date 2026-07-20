class Review < ApplicationRecord
  belongs_to :user
  belongs_to :workshop
  belongs_to :service_request

  has_many_attached :images

  MAX_IMAGES = 5

  enum :status, { published: 0, hidden: 1, flagged: 2 }

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :service_request_id, uniqueness: true

  validate :service_request_completed
  validate :service_request_belongs_to_user
  validate :acceptable_images

  scope :published, -> { where(status: :published) }
  scope :recent, -> { order(created_at: :desc) }

  after_save :recompute_workshop_rating
  after_destroy :recompute_workshop_rating

  def responded?
    response.present?
  end

  private

  def acceptable_images
    return unless images.attached?

    errors.add(:images, :too_many) if images.attachments.size > MAX_IMAGES
    images.each do |image|
      errors.add(:images, :content_type) unless image.content_type.in?(Workshop::ALLOWED_IMAGE_TYPES)
      errors.add(:images, :file_size) if image.byte_size > Workshop::MAX_PHOTO_SIZE
    end
  end

  def service_request_completed
    return unless service_request

    unless service_request.completed?
      errors.add(:service_request, :not_completed)
    end
  end

  def service_request_belongs_to_user
    return unless service_request && user

    unless service_request.car.user_id == user_id
      errors.add(:service_request, :not_owned_by_reviewer)
    end
  end

  def recompute_workshop_rating
    workshop.recompute_rating!
  end
end
