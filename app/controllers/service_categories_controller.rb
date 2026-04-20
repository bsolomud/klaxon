class ServiceCategoriesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  before_action :set_service_category, only: [:show]

  def index
    @service_categories = ServiceCategory.order(:name)
  end

  def show
    @workshops = @service_category.workshops.active.order(:name)
  end

  private

  def set_service_category
    @service_category = ServiceCategory.find(params[:id])
  end
end
