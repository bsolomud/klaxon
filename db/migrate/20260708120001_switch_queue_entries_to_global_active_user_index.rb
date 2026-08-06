# frozen_string_literal: true

class SwitchQueueEntriesToGlobalActiveUserIndex < ActiveRecord::Migration[8.1]
  def up
    remove_index :queue_entries, name: "index_queue_entries_active_user_per_queue"
    add_index :queue_entries, :user_id, unique: true,
              where: "status = ANY (ARRAY[0, 1, 2])",
              name: "index_queue_entries_active_user"
  end

  def down
    remove_index :queue_entries, name: "index_queue_entries_active_user"
    add_index :queue_entries, [:queue_id, :user_id], unique: true,
              where: "status = ANY (ARRAY[0, 1, 2])",
              name: "index_queue_entries_active_user_per_queue"
  end
end
