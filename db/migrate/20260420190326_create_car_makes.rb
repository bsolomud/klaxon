# frozen_string_literal: true

class CreateCarMakes < ActiveRecord::Migration[8.1]
  def change
    create_table :car_makes do |t|
      t.string :name, null: false
      t.integer :status, null: false, default: 0
      t.references :submitted_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    add_index :car_makes, "lower(name)", unique: true, name: "index_car_makes_on_lower_name"
  end
end
