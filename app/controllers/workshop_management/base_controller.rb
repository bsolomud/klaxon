class WorkshopManagement::BaseController < ApplicationController
  layout "operator"
  before_action :set_current_workshop
  before_action :require_workshop_access!

  private

  def set_current_workshop
    id = params[:workshop_id] || params[:id]
    @workshop = current_user.workshops.active.find(id)
    @other_workshops = current_user.workshops.active.where.not(id: @workshop.id)
  end
end
