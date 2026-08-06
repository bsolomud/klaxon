class WorkshopManagement::WorkingHourExceptionsController < WorkshopManagement::BaseController
  def create
    date = Date.parse(params[:date].to_s)
    @workshop.working_hour_exceptions.find_or_create_by!(date: date) { |e| e.closed = true }
    redirect_to workshop_management_workshop_appointment_slots_path(@workshop, date: date),
      notice: t("workshop_management.closures.added")
  rescue ArgumentError, TypeError
    redirect_to workshop_management_workshop_appointment_slots_path(@workshop),
      alert: t("workshop_management.closures.invalid_date")
  end

  def destroy
    @workshop.working_hour_exceptions.find(params[:id]).destroy
    redirect_to workshop_management_workshop_appointment_slots_path(@workshop),
      notice: t("workshop_management.closures.removed")
  end
end
