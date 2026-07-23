# frozen_string_literal: true

class CreateCarHistoryAccesses < ActiveRecord::Migration[8.1]
  def change
    create_table :car_history_accesses do |t|
      t.references :car, null: false, foreign_key: true
      t.references :workshop, null: false, foreign_key: true
      t.timestamps
    end

    add_index :car_history_accesses, [:car_id, :workshop_id], unique: true
  end
end
