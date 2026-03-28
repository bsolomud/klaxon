class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :confirmable, :lockable,
         :trackable, :recoverable, :rememberable, :validatable, :omniauthable

  enum :role, { driver: 0 }

  has_many :cars, dependent: :destroy
  has_many :car_ownership_records, dependent: :destroy
  has_many :incoming_car_transfers, class_name: "CarTransfer", foreign_key: :to_user_id, dependent: :destroy
  has_many :outgoing_car_transfers, class_name: "CarTransfer", foreign_key: :from_user_id, dependent: :destroy
  has_many :workshop_operators, dependent: :destroy
  has_many :workshops, through: :workshop_operators

  def manages_workshop?(workshop)
    workshop_operators.exists?(workshop: workshop)
  end

  def workshop_owner?
    workshop_operators.owner.exists?
  end

  def full_name
    [first_name, last_name].compact_blank.join(" ").presence
  end
end
