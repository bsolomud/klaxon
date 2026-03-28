class CarTransfersController < ApplicationController
  before_action :set_car_transfer, only: [:show]
  before_action :set_requested_transfer, only: [:approve, :reject, :cancel]

  def new
    @car = Car.find_by!(vin: params[:vin]&.upcase)
    redirect_to cars_path, alert: t("car_transfers.new.own_car") if @car.user_id == current_user.id
  end

  def create
    @car = Car.find_by!(vin: car_transfer_params[:vin]&.upcase)
    return redirect_to cars_path, alert: t("car_transfers.new.own_car") if @car.user_id == current_user.id
    return redirect_to cars_path, alert: t("car_transfers.create.already_active") if @car.car_transfers.active.exists?

    ActiveRecord::Base.transaction do
      @transfer = CarTransfer.create!(
        car: @car,
        from_user: @car.user,
        to_user: current_user
      )
      CarTransferEvent.create!(
        car_transfer: @transfer,
        actor: current_user,
        event_type: :transfer_requested
      )
    end

    redirect_to car_transfer_path(@transfer), notice: t("car_transfers.create.success")
  end

  def show
    @can_approve = @transfer.requested? && !@transfer.expired? && @transfer.from_user_id == current_user.id
    @can_reject = @can_approve
    @can_cancel = @transfer.requested? && !@transfer.expired? && @transfer.to_user_id == current_user.id
  end

  def approve
    return redirect_to car_transfer_path(@transfer), alert: t("car_transfers.approve.not_authorized") unless @transfer.from_user_id == current_user.id
    return redirect_to car_transfer_path(@transfer), alert: t("car_transfers.approve.expired") if @transfer.expired?

    @transfer.approve!(actor: current_user)
    redirect_to car_transfer_path(@transfer), notice: t("car_transfers.approve.success")
  end

  def reject
    return redirect_to car_transfer_path(@transfer), alert: t("car_transfers.reject.not_authorized") unless @transfer.from_user_id == current_user.id

    @transfer.reject!(actor: current_user)
    redirect_to car_transfer_path(@transfer), notice: t("car_transfers.reject.success")
  end

  def cancel
    return redirect_to car_transfer_path(@transfer), alert: t("car_transfers.cancel.not_authorized") unless @transfer.to_user_id == current_user.id

    @transfer.cancel!(actor: current_user)
    redirect_to car_transfer_path(@transfer), notice: t("car_transfers.cancel.success")
  end

  private

  def set_car_transfer
    @transfer = CarTransfer.includes(:car, :from_user, :to_user).find_by!(token: params[:token])
  end

  def set_requested_transfer
    @transfer = CarTransfer.find_by!(token: params[:token], status: :requested)
  end

  def car_transfer_params
    params.require(:car_transfer).permit(:vin)
  end
end
