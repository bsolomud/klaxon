# frozen_string_literal: true

class AddServiceRequestToQueueEntries < ActiveRecord::Migration[8.1]
  def change
    add_reference :queue_entries, :service_request, foreign_key: true, null: true
  end
end
