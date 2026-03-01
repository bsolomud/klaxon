class ServiceCategoriesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  before_action :set_service_category, only: [:show, :edit, :update, :destroy]

  def index
    @service_categories = ServiceCategory.order(:name)
  end

  def show
    @workshops = @service_category.workshops.active.order(:name)
  end

  def new
    @service_category = ServiceCategory.new
  end

  def create
    @service_category = ServiceCategory.new(service_category_params)

    if @service_category.save
      redirect_to @service_category, notice: t("service_categories.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @service_category.update(service_category_params)
      redirect_to @service_category, notice: t("service_categories.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @service_category.destroy!
    redirect_to service_categories_path, notice: t("service_categories.destroy.success")
  rescue ActiveRecord::DeleteRestrictionError
    redirect_to @service_category, alert: t("service_categories.destroy.has_workshops")
  end

  private

  def set_service_category
    @service_category = ServiceCategory.find(params[:id])
  end

  def service_category_params
    params.expect(service_category: [:name, :slug])
  end
end
