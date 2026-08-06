# frozen_string_literal: true

class CreateWorkshopServiceCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :workshop_service_categories do |t|
      t.references :workshop, null: false, foreign_key: true
      t.references :service_category, null: false, foreign_key: true
      t.decimal :price_min, precision: 10, scale: 2
      t.decimal :price_max, precision: 10, scale: 2
      t.string :price_unit
      t.string :currency, default: "UAH"
      t.integer :estimated_duration_minutes
      t.timestamps
    end

    add_index :workshop_service_categories, [:workshop_id, :service_category_id],
              unique: true, name: "index_wsc_on_workshop_id_and_service_category_id"
  end
end
