class MyWorkshopsController < ApplicationController
  def index
    @workshops = current_user.workshops.includes(:service_categories).order(:name)
  end
end
