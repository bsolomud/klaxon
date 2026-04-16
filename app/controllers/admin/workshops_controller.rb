class Admin::WorkshopsController < Admin::BaseController
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
    case event
    when "approve"
      WorkshopMailer.with(workshop: @workshop).approved.deliver_later
      notify_owners(:workshop_approved, @workshop)
    when "decline"
      WorkshopMailer.with(workshop: @workshop).declined.deliver_later
      notify_owners(:workshop_declined, @workshop)
    end
  end

  def notify_owners(event, notifiable)
    owner_ids = @workshop.workshop_operators.where(role: :owner).pluck(:user_id)
    owner_ids.each do |user_id|
      Notification.create!(user_id: user_id, notifiable: notifiable, event: event)
    end
  end
end
