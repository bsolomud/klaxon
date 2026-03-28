class Admin::WorkshopsController < Admin::BaseController
  before_action :set_workshop, only: %i[show transition]

  TRANSITIONS = {
    "approve"  => { from: :pending,  to: :active },
    "decline"  => { from: :pending,  to: :declined },
    "suspend"  => { from: :active,   to: :suspended }
  }.freeze

  def index
    @workshops = Workshop.order(created_at: :desc)
    @workshops = @workshops.where(status: params[:status]) if params[:status].present?
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

    redirect_to admin_workshop_path(@workshop), notice: t("admin.workshops.transition.success")
  end

  private

  def set_workshop
    @workshop = Workshop.includes(:service_categories).find(params[:id])
  end
end
