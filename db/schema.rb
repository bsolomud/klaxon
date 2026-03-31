# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_29_100002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admins", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
  end

  create_table "car_ownership_records", force: :cascade do |t|
    t.bigint "car_id", null: false
    t.bigint "car_transfer_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "ended_at"
    t.datetime "started_at", null: false
    t.bigint "user_id", null: false
    t.index ["car_id"], name: "index_car_ownership_records_on_car_id"
    t.index ["car_transfer_id"], name: "index_car_ownership_records_on_car_transfer_id"
    t.index ["user_id"], name: "index_car_ownership_records_on_user_id"
  end

  create_table "car_transfer_events", force: :cascade do |t|
    t.bigint "actor_id"
    t.bigint "car_transfer_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "event_type", null: false
    t.jsonb "metadata"
    t.index ["actor_id"], name: "index_car_transfer_events_on_actor_id"
    t.index ["car_transfer_id"], name: "index_car_transfer_events_on_car_transfer_id"
  end

  create_table "car_transfers", force: :cascade do |t|
    t.bigint "car_id", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "from_user_id", null: false
    t.integer "status", default: 0, null: false
    t.bigint "to_user_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["car_id"], name: "index_car_transfers_on_car_id"
    t.index ["car_id"], name: "index_car_transfers_one_active_per_car", unique: true, where: "(status = 0)"
    t.index ["from_user_id"], name: "index_car_transfers_on_from_user_id"
    t.index ["to_user_id"], name: "index_car_transfers_on_to_user_id"
    t.index ["token"], name: "index_car_transfers_on_token", unique: true
  end

  create_table "cars", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "engine_volume", precision: 3, scale: 1
    t.integer "fuel_type", default: 0, null: false
    t.string "license_plate", null: false
    t.string "make", null: false
    t.string "model", null: false
    t.integer "odometer"
    t.integer "transmission"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "vin"
    t.integer "year", null: false
    t.index "lower((license_plate)::text)", name: "index_cars_on_lower_license_plate", unique: true
    t.index ["user_id"], name: "index_cars_on_user_id"
    t.index ["vin"], name: "index_cars_on_vin", unique: true
  end

  create_table "queue_entries", force: :cascade do |t|
    t.datetime "called_at"
    t.bigint "car_id"
    t.datetime "created_at", null: false
    t.integer "estimated_wait_minutes"
    t.datetime "joined_at", null: false
    t.integer "lock_version", default: 0, null: false
    t.integer "position", null: false
    t.bigint "queue_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["car_id"], name: "index_queue_entries_on_car_id"
    t.index ["queue_id", "position"], name: "index_queue_entries_on_queue_id_and_position", unique: true
    t.index ["queue_id", "user_id"], name: "index_queue_entries_active_user_per_queue", unique: true, where: "(status = ANY (ARRAY[0, 1, 2]))"
    t.index ["queue_id"], name: "index_queue_entries_on_queue_id"
    t.index ["user_id"], name: "index_queue_entries_on_user_id"
  end

  create_table "queues", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.bigint "service_category_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "workshop_id", null: false
    t.index ["service_category_id"], name: "index_queues_on_service_category_id"
    t.index ["workshop_id", "service_category_id", "date"], name: "index_queues_on_workshop_category_date", unique: true
    t.index ["workshop_id"], name: "index_queues_on_workshop_id"
  end

  create_table "service_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_service_categories_on_slug", unique: true
  end

  create_table "service_records", force: :cascade do |t|
    t.datetime "completed_at", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "UAH", null: false
    t.decimal "labor_cost", precision: 10, scale: 2
    t.date "next_service_at_date"
    t.integer "next_service_at_km"
    t.integer "odometer_at_service"
    t.decimal "parts_cost", precision: 10, scale: 2
    t.jsonb "parts_used"
    t.string "performed_by"
    t.text "recommendations"
    t.bigint "service_request_id", null: false
    t.text "summary", null: false
    t.datetime "updated_at", null: false
    t.index ["service_request_id"], name: "index_service_records_on_service_request_id", unique: true
  end

  create_table "service_requests", force: :cascade do |t|
    t.bigint "car_id", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.integer "lock_version", default: 0, null: false
    t.datetime "preferred_time", null: false
    t.jsonb "price_snapshot"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "workshop_id", null: false
    t.bigint "workshop_service_category_id", null: false
    t.index ["car_id", "status"], name: "index_service_requests_on_car_id_and_status"
    t.index ["car_id"], name: "index_service_requests_on_car_id"
    t.index ["workshop_id", "status"], name: "index_service_requests_on_workshop_id_and_status"
    t.index ["workshop_id"], name: "index_service_requests_on_workshop_id"
    t.index ["workshop_service_category_id"], name: "index_service_requests_on_workshop_service_category_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.string "middle_name"
    t.string "phone_number"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "working_hours", force: :cascade do |t|
    t.boolean "closed", default: false, null: false
    t.time "closes_at"
    t.datetime "created_at", null: false
    t.integer "day_of_week", null: false
    t.time "opens_at"
    t.datetime "updated_at", null: false
    t.bigint "workshop_id", null: false
    t.index ["day_of_week", "closed", "opens_at", "closes_at"], name: "index_working_hours_on_schedule"
    t.index ["workshop_id", "day_of_week"], name: "index_working_hours_on_workshop_id_and_day_of_week", unique: true
    t.index ["workshop_id"], name: "index_working_hours_on_workshop_id"
  end

  create_table "workshop_operators", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "workshop_id", null: false
    t.index ["user_id", "workshop_id"], name: "index_workshop_operators_on_user_id_and_workshop_id", unique: true
    t.index ["user_id"], name: "index_workshop_operators_on_user_id"
    t.index ["workshop_id"], name: "index_workshop_operators_on_workshop_id"
  end

  create_table "workshop_service_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "UAH"
    t.integer "estimated_duration_minutes"
    t.decimal "price_max", precision: 10, scale: 2
    t.decimal "price_min", precision: 10, scale: 2
    t.string "price_unit"
    t.bigint "service_category_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "workshop_id", null: false
    t.index ["service_category_id"], name: "index_workshop_service_categories_on_service_category_id"
    t.index ["workshop_id", "service_category_id"], name: "index_wsc_on_workshop_id_and_service_category_id", unique: true
    t.index ["workshop_id"], name: "index_workshop_service_categories_on_workshop_id"
  end

  create_table "workshops", force: :cascade do |t|
    t.string "address", null: false
    t.string "city", null: false
    t.string "country", null: false
    t.datetime "created_at", null: false
    t.text "decline_reason"
    t.text "description"
    t.string "email"
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.string "name", null: false
    t.string "phone", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["city"], name: "index_workshops_on_city"
    t.index ["country"], name: "index_workshops_on_country"
    t.index ["status"], name: "index_workshops_on_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "car_ownership_records", "car_transfers"
  add_foreign_key "car_ownership_records", "cars"
  add_foreign_key "car_ownership_records", "users"
  add_foreign_key "car_transfer_events", "car_transfers"
  add_foreign_key "car_transfer_events", "users", column: "actor_id"
  add_foreign_key "car_transfers", "cars"
  add_foreign_key "car_transfers", "users", column: "from_user_id"
  add_foreign_key "car_transfers", "users", column: "to_user_id"
  add_foreign_key "cars", "users"
  add_foreign_key "queue_entries", "cars"
  add_foreign_key "queue_entries", "queues"
  add_foreign_key "queue_entries", "users"
  add_foreign_key "queues", "service_categories"
  add_foreign_key "queues", "workshops"
  add_foreign_key "service_records", "service_requests"
  add_foreign_key "service_requests", "cars"
  add_foreign_key "service_requests", "workshop_service_categories"
  add_foreign_key "service_requests", "workshops"
  add_foreign_key "working_hours", "workshops"
  add_foreign_key "workshop_operators", "users"
  add_foreign_key "workshop_operators", "workshops"
  add_foreign_key "workshop_service_categories", "service_categories"
  add_foreign_key "workshop_service_categories", "workshops"
end
