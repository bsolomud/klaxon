class Admin::CarModelsController < Admin::BaseController
  before_action :set_car_model, only: [:transition]

  TRANSITIONS = {
    "approve" => { from: "pending", to: :approved },
    "reject"  => { from: "pending", to: :rejected }
  }.freeze

  def index
    scope = CarModel.includes(:car_make, :submitted_by).order(created_at: :desc)
    scope = scope.where(status: params[:status]) if valid_status_filter?
    @pagy, @car_models = pagy(scope, limit: 50)
  end

  def transition
    rule = TRANSITIONS[params[:event]]
    if rule && @car_model.status == rule[:from]
      @car_model.update!(status: rule[:to])
      redirect_to admin_car_models_path, notice: t("admin.car_models.transition.success")
    else
      redirect_to admin_car_models_path, alert: t("admin.car_models.transition.invalid_status")
    end
  end

  private

  def valid_status_filter?
    params[:status].present? && params[:status].in?(CarModel.statuses.keys)
  end

  def set_car_model
    @car_model = CarModel.find(params[:id])
  end
end
