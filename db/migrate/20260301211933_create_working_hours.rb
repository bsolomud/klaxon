# frozen_string_literal: true

class CreateWorkingHours < ActiveRecord::Migration[8.1]
  def change
    create_table :working_hours do |t|
      t.references :workshop, null: false, foreign_key: true
      t.integer :day_of_week, null: false
      t.time :opens_at
      t.time :closes_at
      t.boolean :closed, default: false, null: false

      t.timestamps
    end

    add_index :working_hours, [:workshop_id, :day_of_week], unique: true
    add_index :working_hours, [:day_of_week, :closed, :opens_at, :closes_at],
              name: "index_working_hours_on_schedule"
  end
end
