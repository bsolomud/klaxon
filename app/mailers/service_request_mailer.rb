class ServiceRequestMailer < ApplicationMailer
  def created
    @service_request = params[:service_request]
    @workshop = @service_request.workshop
    @recipients = workshop_operator_emails(@workshop)
    return if @recipients.empty?

    mail(
      to: @recipients,
      subject: t("mailers.service_request_mailer.created.subject", workshop: @workshop.name)
    )
  end

  def accepted
    @service_request = params[:service_request]
    @workshop = @service_request.workshop
    @driver = @service_request.car.user

    mail(
      to: @driver.email,
      subject: t("mailers.service_request_mailer.accepted.subject")
    )
  end

  def rejected
    @service_request = params[:service_request]
    @workshop = @service_request.workshop
    @driver = @service_request.car.user

    mail(
      to: @driver.email,
      subject: t("mailers.service_request_mailer.rejected.subject")
    )
  end

  def started
    @service_request = params[:service_request]
    @workshop = @service_request.workshop
    @driver = @service_request.car.user

    mail(
      to: @driver.email,
      subject: t("mailers.service_request_mailer.started.subject")
    )
  end

  def completed
    @service_request = params[:service_request]
    @workshop = @service_request.workshop
    @driver = @service_request.car.user
    @service_record = @service_request.service_record

    mail(
      to: @driver.email,
      subject: t("mailers.service_request_mailer.completed.subject")
    )
  end

  private

  def workshop_operator_emails(workshop)
    workshop.workshop_operators.includes(:user).map { |op| op.user.email }
  end
end
