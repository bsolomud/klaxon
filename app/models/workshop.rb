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
  has_many :reviews, dependent: :destroy

  has_many :working_hours, dependent: :destroy
  accepts_nested_attributes_for :working_hours, allow_destroy: true

  has_one_attached :logo
  has_many_attached :photos

  enum :status, { pending: 0, active: 1, declined: 2, suspended: 3 }

  STATUS_COLORS = {
    "active" => "green", "pending" => "yellow",
    "suspended" => "red", "declined" => "gray"
  }.freeze

  ALLOWED_IMAGE_TYPES = %w[image/png image/jpeg image/webp].freeze
  MAX_PHOTO_SIZE = 10.megabytes
  MAX_LOGO_SIZE = 5.megabytes

  validates :name, presence: true
  validate :acceptable_logo
  validate :acceptable_photos
  validates :phone, presence: true
  validates :address, presence: true
  validates :city, presence: true
  validates :country, presence: true

  scope :text_search, ->(q) { q.blank? ? all : where("name ILIKE :q OR address ILIKE :q", q: "%#{sanitize_sql_like(q)}%") }
  scope :by_city, ->(city) { where(city: city) }
  scope :by_country, ->(country) { where(country: country) }

  scope :near_param, ->(near_string) {
    coords = parse_near_coords(near_string)
    coords ? near_location(*coords) : all
  }

  scope :near_location, ->(lat, lng, radius_km = 10) {
    lat = lat.to_f
    lng = lng.to_f
    delta_lat = radius_km / 111.0
    delta_lng = radius_km / (111.0 * Math.cos(lat * Math::PI / 180))

    where(latitude: (lat - delta_lat)..(lat + delta_lat))
      .where(longitude: (lng - delta_lng)..(lng + delta_lng))
  }

  scope :sorted_by_distance, ->(lat, lng) {
    lat = lat.to_f
    lng = lng.to_f
    select(
      "workshops.*",
      Arel.sql(sanitize_sql_array([
        "CASE WHEN latitude IS NOT NULL AND longitude IS NOT NULL " \
        "THEN (6371 * acos(LEAST(1.0, cos(radians(?)) * cos(radians(latitude)) * " \
        "cos(radians(longitude) - radians(?)) + sin(radians(?)) * sin(radians(latitude))))) " \
        "ELSE 999999 END AS distance",
        lat, lng, lat
      ]))
    ).order(Arel.sql("distance ASC"))
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

  def recompute_rating!
    stats = reviews.published.pick(Arel.sql("AVG(rating), COUNT(*)"))
    update_columns(avg_rating: stats[0]&.round(2), review_count: stats[1].to_i)
  end

  def operator_emails
    workshop_operators.includes(:user).map { |op| op.user.email }
  end

  def owner_emails
    workshop_operators.where(role: :owner).includes(:user).map { |op| op.user.email }
  end

  def full_address
    [address, city, country].compact_blank.join(", ")
  end

  def self.parse_near_coords(near_string)
    return if near_string.blank?

    parts = near_string.split(",")
    return unless parts.size == 2

    lat, lng = parts.map(&:strip)
    coord_pattern = /\A-?\d+(\.\d+)?\z/
    return unless lat.match?(coord_pattern) && lng.match?(coord_pattern)

    [lat.to_f, lng.to_f]
  end

  private

  def needs_geocoding?
    return address.present? if new_record?

    address_changed? || city_changed? || country_changed?
  end

  def acceptable_logo
    return unless logo.attached?

    errors.add(:logo, :content_type) unless logo.content_type.in?(ALLOWED_IMAGE_TYPES)
    errors.add(:logo, :file_size) if logo.byte_size > MAX_LOGO_SIZE
  end

  def acceptable_photos
    return unless photos.attached?

    photos.each do |photo|
      errors.add(:photos, :content_type) unless photo.content_type.in?(ALLOWED_IMAGE_TYPES)
      errors.add(:photos, :file_size) if photo.byte_size > MAX_PHOTO_SIZE
    end
  end
end
