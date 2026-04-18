class Admin::WorkshopsController < Admin::BaseController
  include NotificationDispatch
  before_action :set_workshop, only: %i[show transition]

  TRANSITIONS = {
    "approve"  => { from: :pending,  to: :active },
    "decline"  => { from: :pending,  to: :declined },
    "suspend"  => { from: :active,   to: :suspended }
  }.freeze

  def index
    scope = Workshop.order(created_at: :desc)
    scope = scope.where(status: params[:status]) if params[:status].present?
    @pagy, @workshops = pagy(scope, limit: 50)
  end

  def show
    @owner = @workshop.workshop_operators.find_by(role: :owner)&.user
  end

  def transition
    event = params[:event]
    rule = TRANSITIONS[event]

    unless rule && @workshop.status.to_sym == rule[:from]
      return redirect_to admin_workshop_path(@workshop), alert: t("admin.workshops.transition.invalid_status")
    end

    if event == "decline"
      @workshop.update!(status: rule[:to], decline_reason: params[:decline_reason])
    else
      @workshop.update!(status: rule[:to])
    end

    notify_workshop_owners(event)

    redirect_to admin_workshop_path(@workshop), notice: t("admin.workshops.transition.success")
  end

  private

  def set_workshop
    @workshop = Workshop.includes(:service_categories).find(params[:id])
  end

  def notify_workshop_owners(event)
    owner_ids = @workshop.workshop_operators.where(role: :owner).pluck(:user_id)

    case event
    when "approve"
      dispatch_notification(
        recipients: owner_ids,
        notifiable: @workshop,
        event: :workshop_approved,
        mailer: WorkshopMailer.with(workshop: @workshop).approved
      )
    when "decline"
      dispatch_notification(
        recipients: owner_ids,
        notifiable: @workshop,
        event: :workshop_declined,
        mailer: WorkshopMailer.with(workshop: @workshop).declined
      )
    end
  end
end
