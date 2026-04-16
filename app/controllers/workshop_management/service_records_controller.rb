class WorkshopManagement::ServiceRecordsController < WorkshopManagement::BaseController
  before_action :set_service_request

  def new
    @service_record = @service_request.build_service_record(
      odometer_at_service: @service_request.car.odometer
    )
  end

  def create
    @service_record = @service_request.build_service_record(service_record_params)

    ActiveRecord::Base.transaction do
      @service_record.save!
      @service_request.completed!
    end

    notify_driver_completed(@service_request)

    redirect_to workshop_management_workshop_service_request_path(@workshop, @service_request),
                notice: t(".success")
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  private

  def set_service_request
    @service_request = @workshop.service_requests.in_progress.find(params[:service_request_id])
  end

  def service_record_params
    params.require(:service_record).permit(
      :summary, :recommendations, :performed_by,
      :odometer_at_service, :labor_cost, :parts_cost,
      :next_service_at_km, :next_service_at_date
    )
  end

  def notify_driver_completed(service_request)
    ServiceRequestMailer.with(service_request: service_request).completed.deliver_later
    Notification.create!(
      user: service_request.car.user,
      notifiable: service_request,
      event: :service_request_completed
    )
  end
end
