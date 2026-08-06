# frozen_string_literal: true

class AddOnboardingFlagsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :onboarding_flags, :jsonb, default: {}, null: false
  end
end
