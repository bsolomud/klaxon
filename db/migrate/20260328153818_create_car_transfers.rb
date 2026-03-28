# frozen_string_literal: true

class CreateCarTransfers < ActiveRecord::Migration[8.1]
  def change
    create_table :car_transfers do |t|
      t.references :car, null: false, foreign_key: true
      t.references :from_user, null: false, foreign_key: { to_table: :users }
      t.references :to_user, null: false, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :car_transfers, :token, unique: true
    add_index :car_transfers, :car_id, unique: true, where: "status = 0", name: "index_car_transfers_one_active_per_car"
  end
end
