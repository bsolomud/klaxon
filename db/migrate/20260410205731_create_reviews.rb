# frozen_string_literal: true

class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :workshop, null: false, foreign_key: true, index: false
      t.references :service_request, null: false, foreign_key: true, index: { unique: true }
      t.integer :rating, null: false
      t.text :body
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :reviews, [:workshop_id, :status]
  end
end
