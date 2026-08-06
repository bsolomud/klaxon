# frozen_string_literal: true

class RemoveServiceCategoryIdFromWorkshops < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :workshops, :service_categories
    remove_index :workshops, :service_category_id
    remove_column :workshops, :service_category_id
  end

  def down
    add_reference :workshops, :service_category, null: false, foreign_key: true, index: true
  end
end
