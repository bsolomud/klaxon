class WorkshopManagement::AppointmentSlotsController < WorkshopManagement::BaseController
  def index
    @date = parse_date
    @categories = @workshop.workshop_service_categories.includes(:service_category)
    @slots = @workshop.appointment_slots.for_day(@date).chronological.includes(workshop_service_category: :service_category)
    @closures = @workshop.working_hour_exceptions.upcoming
  end

  def generate
    @date = parse_date
    wsc = @workshop.workshop_service_categories.find(params[:workshop_service_category_id])
    count = SlotAvailability.new(@workshop, wsc, @date).generate!.size
    redirect_to workshop_management_workshop_appointment_slots_path(@workshop, date: @date),
      notice: t("workshop_management.appointment_slots.generate.done", count: count)
  rescue ActiveRecord::RecordNotFound
    redirect_to workshop_management_workshop_appointment_slots_path(@workshop, date: @date),
      alert: t("workshop_management.appointment_slots.generate.no_service")
  end

  private

  def parse_date
    Date.parse(params[:date].to_s)
  rescue ArgumentError, TypeError
    Date.current
  end
end
