class Workshop < ApplicationRecord
  belongs_to :service_category

  has_many :working_hours, dependent: :destroy
  accepts_nested_attributes_for :working_hours, allow_destroy: true

  has_one_attached :logo
  has_many_attached :photos

  validates :name, presence: true
  validates :phone, presence: true
  validates :address, presence: true
  validates :city, presence: true
  validates :country, presence: true
  validates :service_category, presence: true

  scope :active, -> { where(active: true) }
  scope :by_city, ->(city) { where(city: city) }
  scope :by_country, ->(country) { where(country: country) }

  scope :by_category_slug, ->(slug) {
    joins(:service_category).where(service_categories: { slug: slug })
  }

  scope :open_now, -> {
    now = Time.current
    time = now.strftime("%H:%M:%S")
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
    today = working_hours.find_by(day_of_week: Time.current.wday)
    return false if today.nil? || today.closed?

    time = Time.current.strftime("%H:%M:%S")
    opens = today.opens_at.strftime("%H:%M:%S")
    closes = today.closes_at.strftime("%H:%M:%S")

    if opens <= closes
      time >= opens && time <= closes
    else
      time >= opens || time <= closes
    end
  end

  def today_working_hours
    working_hours.find_by(day_of_week: Time.current.wday)
  end
end
