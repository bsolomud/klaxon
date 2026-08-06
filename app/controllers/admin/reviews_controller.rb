class Admin::ReviewsController < Admin::BaseController
  include StateTransitionable

  before_action :set_review, only: [:update]

  ALLOWED_STATUSES = %w[published hidden].freeze

  def index
    @reviews = Review.includes(:user, :workshop, :service_request).order(created_at: :desc)
    @reviews = @reviews.where(status: params[:status]) if params[:status].present? && params[:status].in?(Review.statuses.keys)
  end

  def update
    status = params.require(:status)

    unless status.in?(ALLOWED_STATUSES)
      return redirect_to admin_reviews_path, alert: t("admin.reviews.update.invalid_status")
    end

    transition_status(
      @review,
      transition: "#{status}!".to_sym,
      redirect_path: admin_reviews_path,
      invalid_message: t("admin.reviews.update.invalid_status")
    )
  end

  private

  def set_review
    @review = Review.find(params[:id])
  end
end
