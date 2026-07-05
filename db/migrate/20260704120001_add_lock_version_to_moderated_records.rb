# frozen_string_literal: true

class AddLockVersionToModeratedRecords < ActiveRecord::Migration[8.1]
  def change
    add_column :car_makes, :lock_version, :integer, null: false, default: 0
    add_column :workshops, :lock_version, :integer, null: false, default: 0
    add_column :reviews, :lock_version, :integer, null: false, default: 0
  end
end
