class WorkshopManagement::OperatorsController < WorkshopManagement::BaseController
  before_action :require_owner!
  before_action :set_operator, only: [:update, :destroy]

  def index
    @operators = @workshop.workshop_operators.includes(:user).order(:role, :created_at)
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    return redirect_with(alert: t("workshop_management.operators.no_user")) if user.nil?

    operator = @workshop.workshop_operators.find_or_initialize_by(user: user)
    return redirect_with(alert: t("workshop_management.operators.already_member")) if operator.persisted?

    operator.update!(role: :staff)
    redirect_with(notice: t("workshop_management.operators.added", email: user.email))
  end

  def update
    new_role = operator_params[:role]
    if demoting_last_owner?(@operator, new_role)
      return redirect_with(alert: t("workshop_management.operators.cannot_remove_last_owner"))
    end

    @operator.update!(role: new_role)
    redirect_with(notice: t("workshop_management.operators.role_updated"))
  end

  def destroy
    if last_owner?(@operator)
      return redirect_with(alert: t("workshop_management.operators.cannot_remove_last_owner"))
    end

    @operator.destroy
    redirect_with(notice: t("workshop_management.operators.removed"))
  end

  private

  def set_operator
    @operator = @workshop.workshop_operators.find(params[:id])
  end

  def require_owner!
    return if current_user.workshop_operators.owner.exists?(workshop: @workshop)

    redirect_to workshop_management_workshop_dashboard_path(@workshop),
      alert: t("workshop_management.operators.owner_only")
  end

  def last_owner?(operator)
    operator.owner? && @workshop.workshop_operators.owner.count <= 1
  end

  def demoting_last_owner?(operator, new_role)
    operator.owner? && new_role.to_s != "owner" && last_owner?(operator)
  end

  def redirect_with(**flash)
    redirect_to workshop_management_workshop_operators_path(@workshop), **flash
  end

  def operator_params
    params.require(:workshop_operator).permit(:role)
  end
end
