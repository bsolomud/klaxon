class AppointmentSlot < ApplicationRecord
  Overbooked = Class.new(StandardError)

  belongs_to :workshop
  belongs_to :workshop_service_category
  has_many :service_requests, dependent: :nullify

  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validates :capacity, numericality: { greater_than: 0, only_integer: true }
  validates :booked_count, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :ends_after_starts

  scope :future, -> { where(starts_at: Time.current..) }
  scope :bookable, -> { future.where("booked_count < capacity") }
  scope :for_day, ->(date) { where(starts_at: date.all_day) }
  scope :chronological, -> { order(:starts_at) }

  def full?
    booked_count >= capacity
  end

  def available?
    !full? && starts_at.future?
  end

  def remaining
    [capacity - booked_count, 0].max
  end

  # with_lock reloads the row inside a row-level lock, so two concurrent bookings
  # can never push booked_count past capacity.
  def book!
    with_lock do
      raise Overbooked if full?

      update!(booked_count: booked_count + 1)
    end
  end

  def release!
    with_lock do
      update!(booked_count: booked_count - 1) if booked_count.positive?
    end
  end

  private

  def ends_after_starts
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_at, :must_be_after_start) if ends_at <= starts_at
  end
end
