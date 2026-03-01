# frozen_string_literal: true

class CreateWorkshops < ActiveRecord::Migration[8.1]
  def change
    create_table :workshops do |t|
      t.string :name, null: false
      t.text :description
      t.string :phone, null: false
      t.string :email
      t.string :address, null: false
      t.string :city, null: false
      t.string :country, null: false
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.references :service_category, null: false, foreign_key: true
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :workshops, :city
    add_index :workshops, :country
    add_index :workshops, :active
  end
end
