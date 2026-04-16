class CarTransferMailer < ApplicationMailer
  def requested
    @transfer = params[:transfer]
    @car = @transfer.car
    @from_user = @transfer.from_user
    @to_user = @transfer.to_user

    mail(
      to: @from_user.email,
      subject: t("mailers.car_transfer_mailer.requested.subject")
    )
  end

  def approved
    @transfer = params[:transfer]
    @car = @transfer.car
    @to_user = @transfer.to_user

    mail(
      to: @to_user.email,
      subject: t("mailers.car_transfer_mailer.approved.subject")
    )
  end

  def rejected
    @transfer = params[:transfer]
    @car = @transfer.car
    @to_user = @transfer.to_user

    mail(
      to: @to_user.email,
      subject: t("mailers.car_transfer_mailer.rejected.subject")
    )
  end

  def cancelled
    @transfer = params[:transfer]
    @car = @transfer.car
    @from_user = @transfer.from_user

    mail(
      to: @from_user.email,
      subject: t("mailers.car_transfer_mailer.cancelled.subject")
    )
  end

  def expired
    @transfer = params[:transfer]
    @car = @transfer.car

    mail(
      to: [@transfer.from_user.email, @transfer.to_user.email],
      subject: t("mailers.car_transfer_mailer.expired.subject")
    )
  end
end
