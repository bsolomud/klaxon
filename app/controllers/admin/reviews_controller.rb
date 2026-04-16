class Admin::ReviewsController < Admin::BaseController
  before_action :set_review, only: [:update]

  ALLOWED_STATUSES = %w[published hidden].freeze

  def index
    @reviews = Review.includes(:user, :workshop, :service_request).order(created_at: :desc)
    @reviews = @reviews.where(status: params[:status]) if params[:status].present? && params[:status].in?(Review.statuses.keys)
  end

  def update
    status = params.require(:status)

    unless status.in?(ALLOWED_STATUSES)
      redirect_to admin_reviews_path, alert: t("admin.reviews.update.invalid_status")
      return
    end

    @review.update!(status: status)
    redirect_to admin_reviews_path, notice: t("admin.reviews.update.success")
  end

  private

  def set_review
    @review = Review.find(params[:id])
  end
end
