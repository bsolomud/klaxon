class WorkshopsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  before_action :set_workshop, only: [:show, :edit, :update, :destroy]
  before_action :require_workshop_access!, only: [:edit, :update, :destroy]
  before_action :load_service_categories, only: [:new, :create, :edit, :update]
  before_action :build_missing_records, only: [:edit]

  def index
    @workshops = Workshop.active.includes(:service_categories, :working_hours).order(:name)
    @workshops = @workshops.by_city(params[:city]) if params[:city].present?
    @workshops = @workshops.by_country(params[:country]) if params[:country].present?
    @workshops = @workshops.by_category_slug(params[:category]) if params[:category].present?
    @workshops = @workshops.open_now if params[:open_now].present?
    @workshops = @workshops.near_param(params[:near])
  end

  def show
    @working_hours = @workshop.working_hours.order(:day_of_week)
  end

  def new
    @workshop = Workshop.new
    build_missing_records
  end

  def create
    @workshop = Workshop.new(workshop_params)

    unless @workshop.valid?
      build_missing_records
      return render :new, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      @workshop.save!
      @workshop.workshop_operators.create!(user: current_user, role: :owner)
    end
    redirect_to @workshop, notice: t("workshops.create.submitted")
  end

  def edit
  end

  def update
    if @workshop.update(workshop_params)
      redirect_to @workshop, notice: t("workshops.update.success")
    else
      build_missing_records
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @workshop.destroy!
    redirect_to workshops_path, notice: t("workshops.destroy.success")
  end

  private

  def set_workshop
    @workshop = Workshop.includes(workshop_service_categories: :service_category).find(params[:id])

    return unless action_name == "show"
    return if @workshop.active?
    return if user_signed_in? && current_user.manages_workshop?(@workshop)

    raise ActiveRecord::RecordNotFound
  end

  def load_service_categories
    @service_categories = ServiceCategory.order(:name)
  end

  def build_missing_records
    @workshop.build_missing_working_hours
    @workshop.build_missing_service_categories(@service_categories)
    @sorted_workshop_service_categories = @workshop.workshop_service_categories
      .sort_by { |wsc| wsc.service_category&.name.to_s }
  end

  def workshop_params
    params.require(:workshop).permit(
      :name, :description, :phone, :email,
      :address, :city, :country,
      :latitude, :longitude,
      :logo, photos: [],
      working_hours_attributes: [:id, :day_of_week, :opens_at, :closes_at, :closed, :_destroy],
      workshop_service_categories_attributes: [
        :id, :service_category_id, :price_min, :price_max,
        :price_unit, :estimated_duration_minutes, :_destroy
      ]
    )
  end
end
