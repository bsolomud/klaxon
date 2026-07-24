class ReviewsController < ApplicationController
  include NotificationDispatch

  before_action :set_service_request
  before_action :set_review, only: [:edit, :update, :destroy]
  before_action :redirect_if_reviewed, only: [:new, :create]

  def new
    @review = @service_request.build_review(user: current_user, workshop: @service_request.workshop)
  end

  def create
    @review = @service_request.build_review(review_params)
    @review.user = current_user
    @review.workshop = @service_request.workshop

    if @review.save
      dispatch_notification(
        recipients: @service_request.workshop.workshop_operators.pluck(:user_id),
        notifiable: @review,
        event: :review_received
      )
      redirect_to workshop_path(@service_request.workshop), notice: t("reviews.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @review.update(review_params)
      redirect_to workshop_path(@review.workshop), notice: t("reviews.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @review.destroy
    redirect_to service_request_path(@service_request), notice: t("reviews.destroy.success"), status: :see_other
  end

  private

  def set_service_request
    @service_request = ServiceRequest
      .where(car: current_user.cars)
      .completed
      .find(params[:service_request_id])
  end

  def set_review
    @review = @service_request.review
    redirect_to service_request_path(@service_request), alert: t("reviews.not_found") if @review.nil?
  end

  def redirect_if_reviewed
    return if @service_request.review.blank?

    redirect_to service_request_path(@service_request), alert: t("reviews.create.already_reviewed")
  end

  def review_params
    params.require(:review).permit(:rating, :body, images: [])
  end
end
