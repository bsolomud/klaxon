class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: :show

  def index
    @users = User.order(created_at: :desc)
  end

  def show
    @workshops = @user.workshops.includes(:service_categories)
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
