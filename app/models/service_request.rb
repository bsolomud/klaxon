class ServiceRequest < ApplicationRecord
  include PriceFormattable

  belongs_to :car
  belongs_to :workshop
  belongs_to :workshop_service_category
  belongs_to :appointment_slot, optional: true

  has_one :service_record, dependent: :destroy
  has_one :review, dependent: :destroy

  enum :status, { pending: 0, accepted: 1, rejected: 2, in_progress: 3, completed: 4 }

  STATUS_COLORS = {
    "pending" => "yellow", "accepted" => "blue", "rejected" => "red",
    "in_progress" => "indigo", "completed" => "green"
  }.freeze

  validates :description, presence: true
  validates :preferred_time, presence: true

  before_create :snapshot_price
  after_update_commit :broadcast_status_change, if: :saved_change_to_status?

  validate :service_offered_by_workshop
  validate :preferred_time_within_working_hours
  validate :preferred_time_not_in_past, on: :create

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

    # Store string keys so an in-request render of an unsaved record reads the
    # same shape that display_price expects (jsonb round-trips as strings).
    self.price_snapshot = {
      min: workshop_service_category.price_min,
      max: workshop_service_category.price_max,
      unit: workshop_service_category.price_unit,
      currency: workshop_service_category.currency
    }.compact.deep_stringify_keys
  end

  def service_offered_by_workshop
    return unless workshop_service_category && workshop

    if workshop_service_category.workshop_id != workshop_id
      errors.add(:workshop_service_category, :not_offered_by_workshop)
    end
  end

  # Rule 8 (ai/patterns/service_requests.md): preferred_time must fall within the
  # workshop's hours for that weekday. When the workshop has not configured that
  # day at all, we don't block the request (nothing to validate against).
  def preferred_time_within_working_hours
    return if preferred_time.blank? || workshop.blank?

    hours = workshop.working_hours.find_by(day_of_week: preferred_time.wday)
    return if hours.nil?

    if hours.closed?
      errors.add(:preferred_time, :workshop_closed)
      return
    end

    time = preferred_time.strftime(Workshop::TIME_FORMAT)
    opens = hours.opens_at.strftime(Workshop::TIME_FORMAT)
    closes = hours.closes_at.strftime(Workshop::TIME_FORMAT)
    return if Workshop.time_within_range?(time, opens, closes)

    errors.add(:preferred_time, :outside_working_hours)
  end

  def preferred_time_not_in_past
    return if preferred_time.blank?

    errors.add(:preferred_time, :in_the_past) if preferred_time < Time.current
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
