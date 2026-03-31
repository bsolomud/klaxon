class DashboardController < ApplicationController
  def index
    @cars = current_user.cars.order(created_at: :desc)
    @service_requests = ServiceRequest
      .includes(:workshop, :car)
      .where(car: current_user.cars)
      .order(created_at: :desc)
      .limit(5)
    @workshops = current_user.workshops.active
  end
end
