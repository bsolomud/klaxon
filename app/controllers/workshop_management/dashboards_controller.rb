class WorkshopManagement::DashboardsController < WorkshopManagement::BaseController
  def show
    @service_categories = @workshop.workshop_service_categories
                                   .includes(:service_category)
    @working_hours = @workshop.working_hours.order(:day_of_week)
  end
end
