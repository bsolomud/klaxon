class WorkshopManagement::ServiceRequestsController < WorkshopManagement::BaseController
  include StateTransitionable
  include NotificationDispatch

  before_action :set_service_request, only: [:show, :accept, :reject, :start]

  def index
    scope = @workshop.service_requests
                     .includes(:car, workshop_service_category: :service_category)
                     .recent
    scope = scope.where(status: params[:status]) if params[:status].present?
    @pagy, @service_requests = pagy(scope, limit: 20)
  end

  def show
  end

  def accept
    transition_service_request(:pending, :accepted!, notify: :accepted)
  end

  def reject
    transition_service_request(:pending, :rejected!, notify: :rejected)
  end

  def start
    transition_service_request(:accepted, :in_progress!, notify: :started)
  end

  private

  def set_service_request
    @service_request = @workshop.service_requests.find(params[:id])
  end

  def transition_service_request(required_status, transition, notify:)
    transition_status(
      @service_request,
      required_status: required_status,
      transition: transition,
      redirect_path: workshop_management_workshop_service_request_path(@workshop, @service_request),
      invalid_message: t("workshop_management.service_requests.invalid_transition"),
      after_success: ->(record) {
        dispatch_notification(
          recipients: record.car.user,
          notifiable: record,
          event: "service_request_#{notify}",
          mailer: ServiceRequestMailer.with(service_request: record).public_send(notify)
        )
      }
    )
  end
end
