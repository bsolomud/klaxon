class WorkshopManagement::ServiceRequestsController < WorkshopManagement::BaseController
  include StateTransitionable

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
    transition_service_request(:pending, :accepted!)
  end

  def reject
    transition_service_request(:pending, :rejected!)
  end

  def start
    transition_service_request(:accepted, :in_progress!)
  end

  private

  def set_service_request
    @service_request = @workshop.service_requests.find(params[:id])
  end

  def transition_service_request(required_status, transition)
    transition_status(
      @service_request,
      required_status: required_status,
      transition: transition,
      redirect_path: workshop_management_workshop_service_request_path(@workshop, @service_request),
      invalid_message: t("workshop_management.service_requests.invalid_transition")
    )
  end
end
