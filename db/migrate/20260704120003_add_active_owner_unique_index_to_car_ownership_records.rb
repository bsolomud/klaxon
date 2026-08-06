# frozen_string_literal: true

class AddActiveOwnerUniqueIndexToCarOwnershipRecords < ActiveRecord::Migration[8.1]
  def change
    # Enforce a single active (open-ended) ownership record per car at the DB
    # level, instead of relying solely on application code in CarTransfer#approve!.
    add_index :car_ownership_records, :car_id, unique: true,
              where: "ended_at IS NULL",
              name: "index_car_ownership_records_active_owner"
  end
end
