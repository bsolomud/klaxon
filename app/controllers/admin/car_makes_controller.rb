class Admin::CarMakesController < Admin::BaseController
  before_action :set_car_make, only: [:transition]

  TRANSITIONS = {
    "approve" => { from: :pending, to: :approved },
    "reject"  => { from: :pending, to: :rejected }
  }.freeze

  def index
    scope = CarMake.includes(:submitted_by).order(created_at: :desc)
    scope = scope.where(status: params[:status]) if params[:status].present?
    @pagy, @car_makes = pagy(scope, limit: 50)
  end

  def transition
    event = params[:event]
    rule = TRANSITIONS[event]

    unless rule && @car_make.status.to_sym == rule[:from]
      return redirect_to admin_car_makes_path, alert: t("admin.car_makes.transition.invalid_status")
    end

    @car_make.update!(status: rule[:to])

    if event == "approve"
      @car_make.car_models.pending.update_all(status: :approved)
    end

    redirect_to admin_car_makes_path, notice: t("admin.car_makes.transition.success")
  end

  private

  def set_car_make
    @car_make = CarMake.find(params[:id])
  end
end
