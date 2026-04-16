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
        Notification.create!(
          user: transfer.from_user,
          notifiable: transfer,
          event: :car_transfer_expired
        )
        Notification.create!(
          user: transfer.to_user,
          notifiable: transfer,
          event: :car_transfer_expired
        )
      end

      CarTransferMailer.with(transfer: transfer).expired.deliver_later
    end
  end
end
