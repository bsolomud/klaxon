class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :timeoutable
  devise :database_authenticatable, :registerable, :confirmable, :lockable,
         :trackable, :recoverable, :rememberable, :validatable, :omniauthable

  enum :role, { driver: 0 }

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
