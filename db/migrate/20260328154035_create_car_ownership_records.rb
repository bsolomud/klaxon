# frozen_string_literal: true

class CreateCarOwnershipRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :car_ownership_records do |t|
      t.references :car, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.references :car_transfer, null: true, foreign_key: true
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end
  end
end
