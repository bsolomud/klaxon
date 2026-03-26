class Workshop < ApplicationRecord
  TIME_FORMAT = "%H:%M:%S"

  has_many :workshop_operators, dependent: :destroy
  has_many :operators, through: :workshop_operators, source: :user

  has_many :workshop_service_categories, dependent: :destroy
  has_many :service_categories, through: :workshop_service_categories
  accepts_nested_attributes_for :workshop_service_categories,
    allow_destroy: true,
    reject_if: proc { |attrs| attrs["_destroy"] == "1" && attrs["id"].blank? }

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

  def self.time_within_range?(time, opens, closes)
    if opens <= closes
      time >= opens && time <= closes
    else
      time >= opens || time <= closes
    end
  end
  private_class_method :time_within_range?
end
