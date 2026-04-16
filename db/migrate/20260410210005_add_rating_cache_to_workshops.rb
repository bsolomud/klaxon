# frozen_string_literal: true

class AddRatingCacheToWorkshops < ActiveRecord::Migration[8.1]
  def change
    add_column :workshops, :avg_rating, :decimal, precision: 3, scale: 2
    add_column :workshops, :review_count, :integer, default: 0, null: false
  end
end
