# frozen_string_literal: true

class CreateServiceRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :service_records do |t|
      t.references :service_request, null: false, foreign_key: true, index: { unique: true }
      t.text :summary, null: false
      t.text :recommendations
      t.string :performed_by
      t.integer :odometer_at_service
      t.jsonb :parts_used
      t.decimal :labor_cost, precision: 10, scale: 2
      t.decimal :parts_cost, precision: 10, scale: 2
      t.string :currency, null: false, default: "UAH"
      t.integer :next_service_at_km
      t.date :next_service_at_date
      t.datetime :completed_at, null: false

      t.timestamps
    end
  end
end
