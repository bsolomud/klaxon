class Admin::CarMakesController < Admin::BaseController
  include StateTransitionable

  before_action :set_car_make, only: [:transition]

  TRANSITIONS = {
    "approve" => { from: :pending, to: :approved },
    "reject"  => { from: :pending, to: :rejected }
  }.freeze

  def index
    scope = CarMake.includes(:submitted_by).order(created_at: :desc)
    scope = scope.where(status: params[:status]) if valid_status_filter?
    @pagy, @car_makes = pagy(scope, limit: 50)
  end

  def transition
    rule = TRANSITIONS[params[:event]]
    unless rule
      return redirect_to admin_car_makes_path, alert: t("admin.car_makes.transition.invalid_status")
    end

    transition_status(
      @car_make,
      required_status: rule[:from],
      transition: "#{rule[:to]}!".to_sym,
      redirect_path: admin_car_makes_path,
      invalid_message: t("admin.car_makes.transition.invalid_status"),
      after_success: cascade_model_approval(params[:event])
    )
  end

  private

  # When a make is approved, promote its still-pending models alongside it.
  def cascade_model_approval(event)
    return unless event == "approve"

    ->(car_make) { car_make.car_models.pending.update_all(status: :approved) }
  end

  def valid_status_filter?
    params[:status].present? && params[:status].in?(CarMake.statuses.keys)
  end

  def set_car_make
    @car_make = CarMake.find(params[:id])
  end
end
