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
    @available_slots = bookable_slots

    @service_request.car = @cars.first if @cars.size == 1
  end

  def create
    @workshop = Workshop.active.find(service_request_params[:workshop_id])
    @car = current_user.cars.find(service_request_params[:car_id])
    requested_slot_id = params.dig(:service_request, :appointment_slot_id).presence
    @slot = @workshop.appointment_slots.bookable.find_by(id: requested_slot_id) if requested_slot_id

    @service_request = ServiceRequest.new(service_request_params)
    @service_request.car = @car
    @service_request.workshop = @workshop

    if requested_slot_id && @slot.nil?
      load_form_collections
      flash.now[:alert] = t("service_requests.create.slot_taken")
      return render :new, status: :unprocessable_entity
    end

    apply_slot(@service_request, @slot) if @slot

    if save_request
      dispatch_notification(
        recipients: @service_request.workshop.workshop_operators.pluck(:user_id),
        notifiable: @service_request,
        event: :service_request_created,
        mailer: ServiceRequestMailer.with(service_request: @service_request).created
      )
      redirect_to @service_request, notice: t("service_requests.create.success")
    else
      load_form_collections
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

  # Booking a slot fixes the service and time; the slot booking and the request
  # save share a transaction so an overbooked slot rolls the whole thing back.
  def apply_slot(request, slot)
    request.appointment_slot = slot
    request.workshop_service_category_id = slot.workshop_service_category_id
    request.preferred_time = slot.starts_at
  end

  def save_request
    ServiceRequest.transaction do
      @slot&.book!
      @service_request.save!
    end
    true
  rescue AppointmentSlot::Overbooked
    flash.now[:alert] = t("service_requests.create.slot_taken")
    false
  rescue ActiveRecord::RecordInvalid
    false
  end

  def load_form_collections
    @cars = current_user.cars.order(:make, :model)
    @categories = @workshop.workshop_service_categories.includes(:service_category)
    @available_slots = bookable_slots
  end

  def bookable_slots
    @workshop.appointment_slots.bookable.chronological.includes(workshop_service_category: :service_category)
  end
end
