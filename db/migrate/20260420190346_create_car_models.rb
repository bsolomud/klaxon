# frozen_string_literal: true

class CreateCarModels < ActiveRecord::Migration[8.1]
  def change
    create_table :car_models do |t|
      t.references :car_make, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :status, null: false, default: 0
      t.references :submitted_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    add_index :car_models, "car_make_id, lower(name)", unique: true, name: "index_car_models_on_make_and_lower_name"
  end
end
