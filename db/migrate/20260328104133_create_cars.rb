# frozen_string_literal: true

class CreateCars < ActiveRecord::Migration[8.1]
  def change
    create_table :cars do |t|
      t.references :user, null: false, foreign_key: true
      t.string :make, null: false
      t.string :model, null: false
      t.integer :year, null: false
      t.string :license_plate, null: false
      t.string :vin
      t.integer :fuel_type, null: false, default: 0
      t.integer :odometer
      t.decimal :engine_volume, precision: 3, scale: 1
      t.integer :transmission
      t.timestamps
    end

    add_index :cars, "lower(license_plate)", unique: true, name: "index_cars_on_lower_license_plate"
    add_index :cars, :vin, unique: true
  end
end
