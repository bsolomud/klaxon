class CarsController < ApplicationController
  before_action :set_car, only: [:show, :edit, :update, :destroy]

  def index
    @pagy, @cars = pagy(current_user.cars.order(created_at: :desc), limit: 10)
  end

  def show
    @service_records = @car.service_records
      .includes(service_request: [:workshop, { workshop_service_category: :service_category }])
      .order(completed_at: :desc)
  end

  def new
    @car = current_user.cars.build
  end

  def create
    @car = current_user.cars.build(car_params)

    if @car.save
      redirect_to @car, notice: t("cars.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @car.update(car_params)
      redirect_to @car, notice: t("cars.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @car.destroy
    redirect_to cars_path, notice: t("cars.destroy.success"), status: :see_other
  end

  private

  def set_car
    @car = current_user.cars.find(params[:id])
  end

  def car_params
    params.require(:car).permit(
      :make, :model, :year, :license_plate, :vin,
      :fuel_type, :engine_volume, :transmission
    )
  end
end
