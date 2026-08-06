# frozen_string_literal: true

class AddReminderSentAtToServiceRecords < ActiveRecord::Migration[8.1]
  def change
    add_column :service_records, :reminder_sent_at, :datetime
  end
end
