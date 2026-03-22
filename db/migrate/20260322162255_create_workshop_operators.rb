# frozen_string_literal: true

class CreateWorkshopOperators < ActiveRecord::Migration[8.1]
  def change
    create_table :workshop_operators do |t|
      t.references :user, null: false, foreign_key: true
      t.references :workshop, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.timestamps
    end

    add_index :workshop_operators, [:user_id, :workshop_id], unique: true
  end
end
