class DashboardController < ApplicationController
  def index
    @cars = current_user.cars.order(created_at: :desc)
    @workshops = current_user.workshops.active
    @new_user = @cars.empty? && @workshops.empty?
    @show_welcome_banner = current_user.show_welcome_banner?

    has_cars = @cars.any?
    @has_requests = has_cars && ServiceRequest.where(car_id: @cars.select(:id)).exists?

    @checklist = [
      { key: :add_car, done: has_cars, path: new_car_path },
      { key: :browse_workshops, done: @has_requests, path: workshops_path },
      { key: :submit_request, done: @has_requests, path: has_cars ? workshops_path : nil }
    ]
    @checklist_complete = @checklist.all? { |item| item[:done] }

    unless @new_user
      @service_requests = ServiceRequest
        .includes(:workshop, :car)
        .where(car_id: @cars.select(:id))
        .order(created_at: :desc)
        .limit(5)
    end
  end
end
