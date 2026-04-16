class ServiceRequest < ApplicationRecord
  include PriceFormattable

  belongs_to :car
  belongs_to :workshop
  belongs_to :workshop_service_category

  has_one :service_record, dependent: :destroy
  has_one :review, dependent: :destroy

  enum :status, { pending: 0, accepted: 1, rejected: 2, in_progress: 3, completed: 4 }

  validates :description, presence: true
  validates :preferred_time, presence: true

  before_create :snapshot_price
  after_update_commit :broadcast_status_change, if: :saved_change_to_status?

  validate :service_offered_by_workshop

  scope :recent, -> { order(created_at: :desc) }

  def display_price
    return I18n.t("service_requests.price_on_request") if price_snapshot.blank?

    format_price(
      price_snapshot["min"],
      price_snapshot["max"],
      price_snapshot["currency"]
    )
  end

  private

  def snapshot_price
    return unless workshop_service_category

    self.price_snapshot = {
      min: workshop_service_category.price_min,
      max: workshop_service_category.price_max,
      unit: workshop_service_category.price_unit,
      currency: workshop_service_category.currency
    }.compact
  end

  def service_offered_by_workshop
    return unless workshop_service_category && workshop

    if workshop_service_category.workshop_id != workshop_id
      errors.add(:workshop_service_category, :not_offered_by_workshop)
    end
  end

  def broadcast_status_change
    broadcast_replace_to(
      "user_#{car.user_id}_requests",
      target: ActionView::RecordIdentifier.dom_id(self),
      partial: "service_requests/service_request",
      locals: { service_request: self }
    )
    broadcast_replace_to(
      "workshop_#{workshop_id}_requests",
      target: ActionView::RecordIdentifier.dom_id(self, :workshop),
      partial: "workshop_management/service_requests/service_request",
      locals: { service_request: self }
    )
  end
end
