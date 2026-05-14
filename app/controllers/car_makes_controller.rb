class CarMakesController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    car_makes = CarMake.approved.order(:name)
    render json: car_makes.select(:id, :name)
  end
end
