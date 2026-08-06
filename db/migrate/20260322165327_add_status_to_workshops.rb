# frozen_string_literal: true

class AddStatusToWorkshops < ActiveRecord::Migration[8.1]
  def change
    add_column :workshops, :status, :integer, default: 0, null: false
    add_index :workshops, :status
    remove_column :workshops, :active, :boolean, default: true, null: false
  end
end
