class Admin::WorkshopsController < Admin::BaseController
  before_action :set_workshop, only: %i[show approve decline suspend]

  def index
    @workshops = Workshop.order(created_at: :desc)
    @workshops = @workshops.where(status: params[:status]) if params[:status].present?
  end

  def show
    @owner = @workshop.workshop_operators.find_by(role: :owner)&.user
  end

  def approve
    if @workshop.pending?
      @workshop.active!
      redirect_to admin_workshop_path(@workshop), notice: t(".success")
    else
      redirect_to admin_workshop_path(@workshop), alert: t(".invalid_status")
    end
  end

  def decline
    if @workshop.pending?
      @workshop.update!(status: :declined, decline_reason: params[:decline_reason])
      redirect_to admin_workshop_path(@workshop), notice: t(".success")
    else
      redirect_to admin_workshop_path(@workshop), alert: t(".invalid_status")
    end
  end

  def suspend
    if @workshop.active?
      @workshop.suspended!
      redirect_to admin_workshop_path(@workshop), notice: t(".success")
    else
      redirect_to admin_workshop_path(@workshop), alert: t(".invalid_status")
    end
  end

  private

  def set_workshop
    @workshop = Workshop.includes(:service_categories).find(params[:id])
  end
end
