# frozen_string_literal: true

class AddNullCategoryUniqueIndexToQueues < ActiveRecord::Migration[8.1]
  def change
    # The composite unique index on [workshop_id, service_category_id, date] does
    # not constrain workshop-wide queues, because Postgres treats NULL
    # service_category_id values as distinct. This partial index guarantees a
    # single open queue per workshop/day when no category is set.
    add_index :queues, [:workshop_id, :date], unique: true,
              where: "service_category_id IS NULL",
              name: "index_queues_on_workshop_date_when_category_null"
  end
end
