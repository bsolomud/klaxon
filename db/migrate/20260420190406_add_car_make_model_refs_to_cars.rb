# frozen_string_literal: true

class AddCarMakeModelRefsToCars < ActiveRecord::Migration[8.1]
  def change
    add_reference :cars, :car_make, foreign_key: true, null: true
    add_reference :cars, :car_model, foreign_key: true, null: true
  end
end
