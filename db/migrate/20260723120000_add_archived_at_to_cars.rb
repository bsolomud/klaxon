# frozen_string_literal: true

class AddArchivedAtToCars < ActiveRecord::Migration[8.1]
  def change
    add_column :cars, :archived_at, :datetime
    add_index :cars, [:user_id, :archived_at]
  end
end
