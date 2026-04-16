class ReviewsController < ApplicationController
  before_action :set_service_request

  def new
    @review = @service_request.build_review(user: current_user, workshop: @service_request.workshop)
  end

  def create
    @review = @service_request.build_review(review_params)
    @review.user = current_user
    @review.workshop = @service_request.workshop

    if @review.save
      redirect_to workshop_path(@service_request.workshop), notice: t("reviews.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_service_request
    @service_request = ServiceRequest
      .where(car: current_user.cars)
      .completed
      .find(params[:service_request_id])

    if @service_request.review.present?
      redirect_to service_request_path(@service_request), alert: t("reviews.create.already_reviewed")
    end
  end

  def review_params
    params.require(:review).permit(:rating, :body)
  end
end
