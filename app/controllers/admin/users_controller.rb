class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: :show

  def index
    @pagy, @users = pagy(User.order(created_at: :desc), limit: 50)
  end

  def show
    @workshops = @user.workshops.includes(:service_categories)
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
