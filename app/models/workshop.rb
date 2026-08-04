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

  has_many :appointment_slots, dependent: :destroy
  has_many :service_queues, foreign_key: :workshop_id, dependent: :destroy
  has_many :service_requests, dependent: :restrict_with_exception
  has_many :reviews, dependent: :destroy

  has_many :working_hours, dependent: :destroy
  has_many :working_hour_exceptions, dependent: :destroy
  accepts_nested_attributes_for :working_hours, allow_destroy: true

  has_one_attached :logo
  has_many_attached :photos
  has_one_attached :verification_document

  enum :status, { pending: 0, active: 1, declined: 2, suspended: 3 }

  STATUS_COLORS = {
    "active" => "green", "pending" => "yellow",
    "suspended" => "red", "declined" => "gray"
  }.freeze

  ALLOWED_IMAGE_TYPES = %w[image/png image/jpeg image/webp].freeze
  ALLOWED_DOCUMENT_TYPES = (ALLOWED_IMAGE_TYPES + %w[application/pdf]).freeze
  MAX_PHOTO_SIZE = 10.megabytes
  MAX_LOGO_SIZE = 5.megabytes
  MAX_DOCUMENT_SIZE = 10.megabytes

  validates :name, presence: true
  validate :acceptable_logo
  validate :acceptable_photos
  validate :acceptable_verification_document
  validates :phone, presence: true
  validates :address, presence: true
  validates :city, presence: true
  validates :country, presence: true

  # Business-verification fields are required only when a user submits an
  # application through the site (the controller sets `applying`); seeds,
  # fixtures, and admin-side creation stay exempt.
  attr_accessor :applying
  validates :registration_number, presence: true, if: :applying
  validates :contact_name, presence: true, if: :applying

  # Set by the map picker so coordinates chosen on the map aren't overwritten by
  # address-based geocoding.
  attr_accessor :located_on_map

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

  # Uses an IN-subquery (not a join) so it composes with sorted_by_distance's
  # custom select and pagy without duplicating rows. A workshop is open now if
  # today's shift covers the time, or an overnight shift that began yesterday
  # is still running into the early hours.
  scope :open_now, -> {
    now = Time.current
    time = now.strftime(TIME_FORMAT)
    wday = now.wday
    ywday = (wday - 1) % 7

    where(
      id: WorkingHour.where(closed: false).where(
        "(day_of_week = :wday AND " \
        "  ((opens_at <= closes_at AND opens_at <= :time AND closes_at >= :time) " \
        "   OR (opens_at > closes_at AND opens_at <= :time))) " \
        "OR " \
        "(day_of_week = :ywday AND opens_at > closes_at AND closes_at >= :time)",
        time: time, wday: wday, ywday: ywday
      ).select(:workshop_id)
    )
  }

  def open_now?
    return false if closed_on?(Date.current)

    now = Time.current
    time = now.strftime(TIME_FORMAT)

    today = today_working_hours
    if today && !today.closed?
      opens = today.opens_at.strftime(TIME_FORMAT)
      closes = today.closes_at.strftime(TIME_FORMAT)
      if opens <= closes
        return true if self.class.time_within_range?(time, opens, closes)
      elsif time >= opens
        return true # overnight shift starting today, evening portion
      end
    end

    # An overnight shift that began yesterday stays open into today's early
    # hours, until yesterday's closes_at.
    yesterday = working_hours.find { |wh| wh.day_of_week == (now.wday - 1) % 7 }
    return false unless yesterday && !yesterday.closed?

    y_opens = yesterday.opens_at.strftime(TIME_FORMAT)
    y_closes = yesterday.closes_at.strftime(TIME_FORMAT)
    y_opens > y_closes && time <= y_closes
  end

  def today_working_hours
    # Enumerable#find so an eager-loaded :working_hours association is reused
    # (find_by would fire SQL per card on the workshops index).
    working_hours.find { |wh| wh.day_of_week == Time.current.wday }
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

  def verified?
    active?
  end

  def closed_on?(date)
    working_hour_exceptions.exists?(date: date, closed: true)
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
    return false if ActiveModel::Type::Boolean.new.cast(located_on_map)
    return address.present? if new_record?

    address_changed? || city_changed? || country_changed?
  end

  def acceptable_logo
    return unless logo.attached?

    errors.add(:logo, :content_type) unless logo.content_type.in?(ALLOWED_IMAGE_TYPES)
    errors.add(:logo, :file_size) if logo.byte_size > MAX_LOGO_SIZE
  end

  # Restrict to images/PDF so the admin can view it inline without XSS risk.
  def acceptable_verification_document
    return unless verification_document.attached?

    errors.add(:verification_document, :content_type) unless verification_document.content_type.in?(ALLOWED_DOCUMENT_TYPES)
    errors.add(:verification_document, :file_size) if verification_document.byte_size > MAX_DOCUMENT_SIZE
  end

  def acceptable_photos
    return unless photos.attached?

    photos.each do |photo|
      errors.add(:photos, :content_type) unless photo.content_type.in?(ALLOWED_IMAGE_TYPES)
      errors.add(:photos, :file_size) if photo.byte_size > MAX_PHOTO_SIZE
    end
  end
end
