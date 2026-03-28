class ExpireCarTransfersJob < ApplicationJob
  queue_as :default

  def perform
    CarTransfer.requested.where("expires_at < ?", Time.current).find_each do |transfer|
      ActiveRecord::Base.transaction do
        transfer.expired!
        CarTransferEvent.create!(
          car_transfer: transfer,
          event_type: :expired
        )
      end
    end
  end
end
