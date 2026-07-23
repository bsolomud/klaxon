class CarHistoryAccessesController < ApplicationController
  def create
    car = current_user.cars.find(params[:car_id])
    workshop = Workshop.active.find(params[:workshop_id])
    CarHistoryAccess.find_or_create_by!(car: car, workshop: workshop)
    redirect_to car, notice: t("car_history_accesses.create.success", workshop: workshop.name)
  end

  def destroy
    access = CarHistoryAccess.joins(:car)
      .where(cars: { user_id: current_user.id })
      .find(params[:id])
    car = access.car
    access.destroy
    redirect_to car, notice: t("car_history_accesses.destroy.success")
  end
end
