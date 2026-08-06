# frozen_string_literal: true

class AddDeclineReasonToWorkshops < ActiveRecord::Migration[8.1]
  def change
    add_column :workshops, :decline_reason, :text
  end
end
