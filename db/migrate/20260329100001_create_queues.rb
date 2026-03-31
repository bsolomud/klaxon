# frozen_string_literal: true

class CreateQueues < ActiveRecord::Migration[8.1]
  def change
    create_table :queues do |t|
      t.references :workshop, null: false, foreign_key: true
      t.references :service_category, null: true, foreign_key: true
      t.date :date, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :queues, [:workshop_id, :service_category_id, :date], unique: true,
              name: "index_queues_on_workshop_category_date"
  end
end
