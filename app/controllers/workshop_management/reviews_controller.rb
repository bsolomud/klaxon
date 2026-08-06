class WorkshopManagement::ReviewsController < WorkshopManagement::BaseController
  include NotificationDispatch

  before_action :set_review, only: [:respond]

  def index
    @reviews = @workshop.reviews.published.recent.includes(:user).with_attached_images
  end

  def respond
    if @review.update(response_params.merge(responded_at: Time.current))
      dispatch_notification(recipients: @review.user, notifiable: @review, event: :review_replied)
      redirect_to workshop_management_workshop_reviews_path(@workshop),
        notice: t("workshop_management.reviews.respond.success")
    else
      redirect_to workshop_management_workshop_reviews_path(@workshop),
        alert: t("workshop_management.reviews.respond.error")
    end
  end

  private

  def set_review
    @review = @workshop.reviews.find(params[:id])
  end

  def response_params
    params.require(:review).permit(:response)
  end
end
