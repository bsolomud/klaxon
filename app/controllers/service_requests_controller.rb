class ServiceRequestsController < ApplicationController
  include NotificationDispatch
  before_action :set_service_request, only: [:show]

  def index
    scope = ServiceRequest.where(car: current_user.cars).recent
      .includes(:workshop, :car, workshop_service_category: :service_category)
    @pagy, @service_requests = pagy(scope, limit: 20)
  end

  def show
  end

  def new
    @workshop = Workshop.active.find(params[:workshop_id])
    @service_request = ServiceRequest.new(workshop: @workshop)
    @cars = current_user.cars.order(:make, :model)
    @categories = @workshop.workshop_service_categories.includes(:service_category)

    @service_request.car = @cars.first if @cars.size == 1
  end

  def create
    @workshop = Workshop.active.find(service_request_params[:workshop_id])
    @car = current_user.cars.find(service_request_params[:car_id])
    @service_request = ServiceRequest.new(service_request_params)
    @service_request.car = @car
    @service_request.workshop = @workshop

    if @service_request.save
      dispatch_notification(
        recipients: @service_request.workshop.workshop_operators.pluck(:user_id),
        notifiable: @service_request,
        event: :service_request_created,
        mailer: ServiceRequestMailer.with(service_request: @service_request).created
      )
      redirect_to @service_request, notice: t("service_requests.create.success")
    else
      @cars = current_user.cars.order(:make, :model)
      @categories = @workshop.workshop_service_categories.includes(:service_category)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_service_request
    @service_request = ServiceRequest.where(car: current_user.cars).find(params[:id])
  end

  def service_request_params
    params.require(:service_request).permit(
      :car_id, :workshop_id, :workshop_service_category_id,
      :description, :preferred_time
    )
  end
end
