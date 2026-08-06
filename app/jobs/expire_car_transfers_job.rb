class ExpireCarTransfersJob < ApplicationJob
  queue_as :default

  def perform
    CarTransfer.requested.where("expires_at < ?", Time.current).find_each(&:expire!)
  end
end
