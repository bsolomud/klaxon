# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# ============================================================
# Service Categories
# ============================================================

categories = {
  "STO" => "sto",
  "Tire Service" => "tire_service",
  "Car Wash" => "car_wash",
  "Detailing" => "detailing",
  "Evacuator" => "evacuator",
  "Diagnostics" => "diagnostics",
  "Oil Change" => "oil_change",
  "Electric Repair" => "electric",
  "Body Repair" => "body_repair"
}

categories.each do |name, slug|
  ServiceCategory.find_or_create_by!(slug: slug) do |cat|
    cat.name = name
  end
end

puts "Seeded #{ServiceCategory.count} service categories"

# ============================================================
# Example Workshop
# ============================================================

sto = ServiceCategory.find_by!(slug: "sto")

workshop = Workshop.find_or_create_by!(name: "AutoPro Service Center") do |w|
  w.description = "Full-service automotive repair and maintenance center. " \
                  "Certified technicians, modern diagnostic equipment, genuine parts."
  w.phone = "+380441234567"
  w.email = "info@autopro.example.com"
  w.address = "123 Khreshchatyk Street"
  w.city = "Kyiv"
  w.country = "Ukraine"
  w.latitude = 50.4501
  w.longitude = 30.5234
  w.status = :active
end

tire = ServiceCategory.find_by!(slug: "tire_service")
car_wash = ServiceCategory.find_by!(slug: "car_wash")
diagnostics = ServiceCategory.find_by!(slug: "diagnostics")

[
  { service_category: sto, price_min: 500, price_max: 5000, price_unit: "послуга", currency: "UAH", estimated_duration_minutes: 120 },
  { service_category: tire, price_min: 300, price_max: 1200, price_unit: "колесо", currency: "UAH", estimated_duration_minutes: 45 },
  { service_category: car_wash, price_min: 200, price_max: 800, price_unit: "послуга", currency: "UAH", estimated_duration_minutes: 30 },
  { service_category: diagnostics, price_min: 400, price_max: 1500, price_unit: "послуга", currency: "UAH", estimated_duration_minutes: 60 }
].each do |attrs|
  category = attrs.delete(:service_category)
  wsc = WorkshopServiceCategory.find_or_initialize_by(workshop: workshop, service_category: category)
  wsc.assign_attributes(attrs)
  wsc.save!
end

# Working hours: Mon-Fri 08:00-20:00, Sat 09:00-17:00, Sun closed
if workshop.working_hours.empty?
  [
    { day_of_week: 0, closed: true },                                          # Sunday
    { day_of_week: 1, opens_at: "08:00", closes_at: "20:00", closed: false },  # Monday
    { day_of_week: 2, opens_at: "08:00", closes_at: "20:00", closed: false },  # Tuesday
    { day_of_week: 3, opens_at: "08:00", closes_at: "20:00", closed: false },  # Wednesday
    { day_of_week: 4, opens_at: "08:00", closes_at: "20:00", closed: false },  # Thursday
    { day_of_week: 5, opens_at: "08:00", closes_at: "20:00", closed: false },  # Friday
    { day_of_week: 6, opens_at: "09:00", closes_at: "17:00", closed: false }   # Saturday
  ].each do |attrs|
    workshop.working_hours.create!(attrs)
  end
end

puts "Seeded example workshop: #{workshop.name}"

# ============================================================
# Sample Queues
# ============================================================

[sto, tire, car_wash].each do |category|
  queue = ServiceQueue.find_or_create_by!(workshop: workshop, service_category: category, date: Date.current) do |q|
    q.status = :open
  end

  if queue.queue_entries.empty?
    # Create sample users for queue entries
    3.times do |i|
      user = User.find_or_create_by!(email: "queue-user-#{category.slug}-#{i}@example.com") do |u|
        u.password = "password"
        u.confirmed_at = Time.current
      end

      queue.queue_entries.create!(
        user: user,
        position: i + 1,
        joined_at: Time.current - (3 - i).minutes,
        estimated_wait_minutes: i * (category == tire ? 45 : 30)
      )
    end
  end

  puts "Seeded queue for #{workshop.name} — #{category.name} (#{queue.queue_entries.count} entries)"
end

# ============================================================
# Admin Account
# ============================================================

admin_password = ENV.fetch("ADMIN_PASSWORD", "password")

Admin.find_or_create_by!(email: "admin@aulabs.dev") do |admin|
  admin.password = admin_password
end

puts "Seeded admin: admin@aulabs.dev"
