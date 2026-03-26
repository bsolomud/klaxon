class WorkshopsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  before_action :set_workshop, only: [:show, :edit, :update, :destroy]
  before_action :load_service_categories, only: [:new, :create, :edit, :update]

  def index
    @workshops = Workshop.active.includes(:service_categories, :working_hours).order(:name)
    @workshops = @workshops.by_city(params[:city]) if params[:city].present?
    @workshops = @workshops.by_country(params[:country]) if params[:country].present?
    @workshops = @workshops.by_category_slug(params[:category]) if params[:category].present?
    @workshops = @workshops.open_now if params[:open_now].present?
  end

  def show
    @working_hours = @workshop.working_hours.order(:day_of_week)
  end

  def new
    @workshop = Workshop.new
    build_missing_working_hours
    build_missing_service_categories
  end

  def create
    @workshop = Workshop.new(workshop_params)

    if @workshop.save
      redirect_to @workshop, notice: t("workshops.create.success")
    else
      build_missing_working_hours
      build_missing_service_categories
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    build_missing_working_hours
    build_missing_service_categories
  end

  def update
    if @workshop.update(workshop_params)
      redirect_to @workshop, notice: t("workshops.update.success")
    else
      build_missing_working_hours
      build_missing_service_categories
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
  end

  def load_service_categories
    @service_categories = ServiceCategory.order(:name)
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

  def build_missing_working_hours
    existing_days = @workshop.working_hours.map(&:day_of_week)
    (0..6).each do |day|
      @workshop.working_hours.build(day_of_week: day) unless existing_days.include?(day)
    end
  end

  def build_missing_service_categories
    existing_ids = @workshop.workshop_service_categories.map(&:service_category_id)
    @service_categories.each do |category|
      unless existing_ids.include?(category.id)
        wsc = @workshop.workshop_service_categories.build(service_category: category)
        wsc.mark_for_destruction
      end
    end
  end
end
