class CarModelsController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    car_models = CarModel.where(car_make_id: params[:car_make_id]).approved.order(:name)
    render json: car_models.select(:id, :name)
  end
end
