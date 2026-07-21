# frozen_string_literal: true

class CreateAppointmentSlots < ActiveRecord::Migration[8.1]
  def change
    create_table :appointment_slots do |t|
      t.references :workshop, null: false, foreign_key: true
      t.references :workshop_service_category, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :capacity, null: false, default: 1
      t.integer :booked_count, null: false, default: 0
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end

    add_index :appointment_slots, [:workshop_service_category_id, :starts_at],
      unique: true, name: "index_slots_on_wsc_and_start"
    add_index :appointment_slots, [:workshop_id, :starts_at]
  end
end
