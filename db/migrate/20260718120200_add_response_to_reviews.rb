# frozen_string_literal: true

class AddResponseToReviews < ActiveRecord::Migration[8.1]
  def change
    add_column :reviews, :response, :text
    add_column :reviews, :responded_at, :datetime
  end
end
