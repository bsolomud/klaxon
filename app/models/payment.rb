class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :payable, polymorphic: true

  # Only completed-service payments for now; deposits/packages are deferred but
  # will slot in here without reshaping the model.
  enum :kind, { service_payment: 0 }
  enum :status, { pending: 0, processing: 1, paid: 2, failed: 3, refunded: 4, cancelled: 5 }

  validates :amount, numericality: { greater_than: 0 }
  validates :currency, presence: true

  scope :successful, -> { where(status: :paid) }

  def mark_paid!
    update!(status: :paid, paid_at: Time.current)
  end

  def finalized?
    paid? || refunded? || cancelled? || failed?
  end
end
