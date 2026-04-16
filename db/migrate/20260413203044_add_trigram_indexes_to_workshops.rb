# frozen_string_literal: true

class AddTrigramIndexesToWorkshops < ActiveRecord::Migration[8.1]
  def change
    add_index :workshops, :name, using: :gin, opclass: :gin_trgm_ops, name: "index_workshops_on_name_trgm"
    add_index :workshops, :address, using: :gin, opclass: :gin_trgm_ops, name: "index_workshops_on_address_trgm"
  end
end
