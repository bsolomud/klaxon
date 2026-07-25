class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :lock, :unlock]

  def index
    @pagy, @users = pagy(User.order(created_at: :desc), limit: 50)
  end

  def show
    @workshops = @user.workshops.includes(:service_categories)
  end

  def lock
    @user.lock_access! unless @user.access_locked?
    redirect_to admin_user_path(@user), notice: t("admin.users.lock.success")
  end

  def unlock
    @user.unlock_access! if @user.access_locked?
    redirect_to admin_user_path(@user), notice: t("admin.users.unlock.success")
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
