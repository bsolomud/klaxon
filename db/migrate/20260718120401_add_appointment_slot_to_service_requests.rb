# frozen_string_literal: true

class AddAppointmentSlotToServiceRequests < ActiveRecord::Migration[8.1]
  def change
    add_reference :service_requests, :appointment_slot, foreign_key: true, null: true
  end
end
