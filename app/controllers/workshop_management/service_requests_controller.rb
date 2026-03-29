class WorkshopManagement::ServiceRequestsController < WorkshopManagement::BaseController
  before_action :set_service_request, only: [:show, :accept, :reject, :start]

  def index
    @service_requests = @workshop.service_requests
                                 .includes(:car, workshop_service_category: :service_category)
                                 .recent
    @service_requests = @service_requests.where(status: params[:status]) if params[:status].present?
  end

  def show
  end

  def accept
    transition_request(:pending, :accepted!)
  end

  def reject
    transition_request(:pending, :rejected!)
  end

  def start
    transition_request(:accepted, :in_progress!)
  end

  private

  def set_service_request
    @service_request = @workshop.service_requests.find(params[:id])
  end

  def transition_request(required_status, transition_method)
    unless @service_request.status == required_status.to_s
      redirect_to workshop_management_workshop_service_request_path(@workshop, @service_request),
                  alert: t("workshop_management.service_requests.invalid_transition")
      return
    end

    @service_request.lock_version = params[:lock_version].to_i
    @service_request.send(transition_method)
    redirect_to workshop_management_workshop_service_request_path(@workshop, @service_request),
                notice: t(".success")
  rescue ActiveRecord::StaleObjectError
    redirect_to workshop_management_workshop_service_request_path(@workshop, @service_request),
                alert: t(".stale")
  end
end
