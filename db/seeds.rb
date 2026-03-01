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
  w.service_category = sto
  w.description = "Full-service automotive repair and maintenance center. " \
                  "Certified technicians, modern diagnostic equipment, genuine parts."
  w.phone = "+380441234567"
  w.email = "info@autopro.example.com"
  w.address = "123 Khreshchatyk Street"
  w.city = "Kyiv"
  w.country = "Ukraine"
  w.latitude = 50.4501
  w.longitude = 30.5234
  w.active = true
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
