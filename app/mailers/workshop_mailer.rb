class WorkshopMailer < ApplicationMailer
  def approved
    @workshop = params[:workshop]
    @recipients = @workshop.owner_emails
    return if @recipients.empty?

    mail(
      to: @recipients,
      subject: t("mailers.workshop_mailer.approved.subject", name: @workshop.name)
    )
  end

  def declined
    @workshop = params[:workshop]
    @decline_reason = @workshop.decline_reason
    @recipients = @workshop.owner_emails
    return if @recipients.empty?

    mail(
      to: @recipients,
      subject: t("mailers.workshop_mailer.declined.subject", name: @workshop.name)
    )
  end
end
