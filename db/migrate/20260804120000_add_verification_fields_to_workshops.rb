# frozen_string_literal: true

class AddVerificationFieldsToWorkshops < ActiveRecord::Migration[8.1]
  def change
    add_column :workshops, :registration_number, :string
    add_column :workshops, :contact_name, :string
  end
end
