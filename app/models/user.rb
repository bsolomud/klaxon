class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :confirmable, :lockable,
         :trackable, :recoverable, :rememberable, :validatable, :omniauthable

  enum :role, { driver: 0 }

  has_many :cars, dependent: :destroy
  has_many :car_ownership_records, dependent: :destroy
  has_many :incoming_car_transfers, class_name: "CarTransfer", foreign_key: :to_user_id, dependent: :destroy
  has_many :outgoing_car_transfers, class_name: "CarTransfer", foreign_key: :from_user_id, dependent: :destroy
  has_many :queue_entries, dependent: :destroy
  has_many :workshop_operators, dependent: :destroy
  has_many :workshops, through: :workshop_operators
  has_many :notifications, dependent: :destroy
  has_many :reviews, dependent: :destroy

  def manages_workshop?(workshop)
    workshop_operators.exists?(workshop: workshop)
  end

  def workshop_owner?
    workshop_operators.owner.exists?
  end

  def full_name
    [first_name, last_name].compact_blank.join(" ").presence
  end

  def show_welcome_banner?
    return false if onboarding_flags["welcome_dismissed"]

    created_at > 7.days.ago
  end

  def dismiss_welcome_banner!
    update!(onboarding_flags: onboarding_flags.merge("welcome_dismissed" => true, "welcome_dismissed_at" => Time.current.iso8601))
  end
end
