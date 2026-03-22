class WorkshopsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  before_action :set_workshop, only: [:show, :edit, :update, :destroy]

  def index
    @workshops = Workshop.active.includes(:service_category).order(:name)
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
    build_working_hours
  end

  def create
    @workshop = Workshop.new(workshop_params)

    if @workshop.save
      redirect_to @workshop, notice: t("workshops.create.success")
    else
      build_missing_working_hours
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    build_missing_working_hours
  end

  def update
    if @workshop.update(workshop_params)
      redirect_to @workshop, notice: t("workshops.update.success")
    else
      build_missing_working_hours
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @workshop.destroy!
    redirect_to workshops_path, notice: t("workshops.destroy.success")
  end

  private

  def set_workshop
    @workshop = Workshop.find(params[:id])
  end

  def workshop_params
    params.require(:workshop).permit(
      :name, :description, :phone, :email,
      :address, :city, :country,
      :latitude, :longitude,
      :service_category_id,
      :logo, photos: [],
      working_hours_attributes: [:id, :day_of_week, :opens_at, :closes_at, :closed, :_destroy]
    )
  end

  # Build all 7 days for new form
  def build_working_hours
    (0..6).each do |day|
      @workshop.working_hours.build(day_of_week: day)
    end
  end

  # Fill in missing days on edit/validation failure
  def build_missing_working_hours
    existing_days = @workshop.working_hours.map(&:day_of_week)
    (0..6).each do |day|
      @workshop.working_hours.build(day_of_week: day) unless existing_days.include?(day)
    end
  end
end
