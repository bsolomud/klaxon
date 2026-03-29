# frozen_string_literal: true

class CreateServiceRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :service_requests do |t|
      t.references :car, null: false, foreign_key: true
      t.references :workshop, null: false, foreign_key: true
      t.references :workshop_service_category, null: false, foreign_key: true
      t.jsonb :price_snapshot
      t.integer :status, null: false, default: 0
      t.text :description, null: false
      t.datetime :preferred_time, null: false
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end

    add_index :service_requests, [:workshop_id, :status]
    add_index :service_requests, [:car_id, :status]
  end
end
