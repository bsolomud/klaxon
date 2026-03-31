# frozen_string_literal: true

class CreateQueueEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :queue_entries do |t|
      t.references :queue, null: false, foreign_key: { to_table: :queues }
      t.references :user, null: false, foreign_key: true
      t.references :car, null: true, foreign_key: true
      t.integer :position, null: false
      t.integer :status, null: false, default: 0
      t.integer :estimated_wait_minutes
      t.datetime :joined_at, null: false
      t.datetime :called_at
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :queue_entries, [:queue_id, :position], unique: true
    add_index :queue_entries, [:queue_id, :user_id], unique: true,
              where: "status IN (0, 1, 2)",
              name: "index_queue_entries_active_user_per_queue"
  end
end
