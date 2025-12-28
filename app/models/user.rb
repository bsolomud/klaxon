class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :timeoutable
  devise :database_authenticatable, :registerable, :confirmable, :lockable,
         :trackable, :recoverable, :rememberable, :validatable, :omniauthable

end
