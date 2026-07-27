# frozen_string_literal: true

class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :payable, polymorphic: true, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :currency, null: false, default: "UAH"
      t.integer :kind, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.string :provider
      t.string :provider_reference
      t.datetime :paid_at
      t.timestamps
    end

    add_index :payments, :provider_reference, unique: true
  end
end
