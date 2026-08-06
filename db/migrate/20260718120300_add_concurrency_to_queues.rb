# frozen_string_literal: true

class AddConcurrencyToQueues < ActiveRecord::Migration[8.1]
  def change
    add_column :queues, :concurrency, :integer, default: 1, null: false
  end
end
