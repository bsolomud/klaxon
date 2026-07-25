# frozen_string_literal: true

class CreateWorkingHourExceptions < ActiveRecord::Migration[8.1]
  def change
    create_table :working_hour_exceptions do |t|
      t.references :workshop, null: false, foreign_key: true
      t.date :date, null: false
      t.boolean :closed, null: false, default: true
      t.timestamps
    end

    add_index :working_hour_exceptions, [:workshop_id, :date], unique: true
  end
end
