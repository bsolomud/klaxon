# frozen_string_literal: true

class CreateCarTransferEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :car_transfer_events do |t|
      t.references :car_transfer, null: false, foreign_key: true
      t.references :actor, foreign_key: { to_table: :users }, null: true
      t.integer :event_type, null: false
      t.jsonb :metadata
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end
  end
end
