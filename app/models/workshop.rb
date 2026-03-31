class Workshop < ApplicationRecord
  TIME_FORMAT = "%H:%M:%S"
  include TimeRangeable

  geocoded_by :full_address
  after_validation :geocode, if: :needs_geocoding?

  has_many :workshop_operators, dependent: :destroy
  has_many :operators, through: :workshop_operators, source: :user

  has_many :workshop_service_categories, dependent: :destroy
  has_many :service_categories, through: :workshop_service_categories
  accepts_nested_attributes_for :workshop_service_categories,
    allow_destroy: true,
    reject_if: proc { |attrs| attrs["_destroy"] == "1" && attrs["id"].blank? }

  has_many :service_queues, foreign_key: :workshop_id, dependent: :destroy
  has_many :service_requests, dependent: :restrict_with_exception

  has_many :working_hours, dependent: :destroy
  accepts_nested_attributes_for :working_hours, allow_destroy: true

  has_one_attached :logo
  has_many_attached :photos

  enum :status, { pending: 0, active: 1, declined: 2, suspended: 3 }

  validates :name, presence: true
  validates :phone, presence: true
  validates :address, presence: true
  validates :city, presence: true
  validates :country, presence: true

  scope :by_city, ->(city) { where(city: city) }
  scope :by_country, ->(country) { where(country: country) }

  scope :near_param, ->(near_string) {
    return all if near_string.blank?

    parts = near_string.split(",")
    return all unless parts.size == 2

    lat, lng = parts.map(&:strip)
    coord_pattern = /\A-?\d+(\.\d+)?\z/
    return all unless lat.match?(coord_pattern) && lng.match?(coord_pattern)

    near_location(lat, lng)
  }

  scope :near_location, ->(lat, lng, radius_km = 10) {
    lat = lat.to_f
    lng = lng.to_f
    delta_lat = radius_km / 111.0
    delta_lng = radius_km / (111.0 * Math.cos(lat * Math::PI / 180))

    where(latitude: (lat - delta_lat)..(lat + delta_lat))
      .where(longitude: (lng - delta_lng)..(lng + delta_lng))
  }

  scope :by_category_slug, ->(slug) {
    joins(:service_categories).where(service_categories: { slug: slug })
  }

  scope :open_now, -> {
    now = Time.current
    time = now.strftime(TIME_FORMAT)
    wday = now.wday

    joins(:working_hours)
      .where(working_hours: { day_of_week: wday, closed: false })
      .where(
        "(working_hours.opens_at <= working_hours.closes_at " \
        " AND working_hours.opens_at <= :time AND working_hours.closes_at >= :time) " \
        "OR " \
        "(working_hours.opens_at > working_hours.closes_at " \
        " AND (working_hours.opens_at <= :time OR working_hours.closes_at >= :time))",
        time: time
      )
  }

  def open_now?
    today_hours = today_working_hours
    return false if today_hours.nil? || today_hours.closed?

    self.class.time_within_range?(
      Time.current.strftime(TIME_FORMAT),
      today_hours.opens_at.strftime(TIME_FORMAT),
      today_hours.closes_at.strftime(TIME_FORMAT)
    )
  end

  def today_working_hours
    working_hours.find_by(day_of_week: Time.current.wday)
  end

  def build_missing_working_hours
    existing_days = working_hours.map(&:day_of_week)
    (0..6).each do |day|
      working_hours.build(day_of_week: day) unless existing_days.include?(day)
    end
  end

  def build_missing_service_categories(all_categories)
    existing_ids = workshop_service_categories.map(&:service_category_id)
    all_categories.each do |category|
      unless existing_ids.include?(category.id)
        wsc = workshop_service_categories.build(service_category: category)
        wsc.mark_for_destruction
      end
    end
  end

  def full_address
    [address, city, country].compact_blank.join(", ")
  end

  private

  def needs_geocoding?
    return address.present? if new_record?

    address_changed? || city_changed? || country_changed?
  end
end
