class WorkshopMailer < ApplicationMailer
  def approved
    @workshop = params[:workshop]
    @recipients = workshop_owner_emails(@workshop)
    return if @recipients.empty?

    mail(
      to: @recipients,
      subject: t("mailers.workshop_mailer.approved.subject", name: @workshop.name)
    )
  end

  def declined
    @workshop = params[:workshop]
    @decline_reason = @workshop.decline_reason
    @recipients = workshop_owner_emails(@workshop)
    return if @recipients.empty?

    mail(
      to: @recipients,
      subject: t("mailers.workshop_mailer.declined.subject", name: @workshop.name)
    )
  end

  private

  def workshop_owner_emails(workshop)
    workshop.workshop_operators.where(role: :owner).includes(:user).map { |op| op.user.email }
  end
end
