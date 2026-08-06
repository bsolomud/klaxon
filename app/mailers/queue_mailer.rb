class QueueMailer < ApplicationMailer
  def called
    @entry = params[:queue_entry]
    @queue = @entry.service_queue
    @workshop = @queue.workshop
    @driver = @entry.user

    mail(
      to: @driver.email,
      subject: t("mailers.queue_mailer.called.subject", workshop: @workshop.name)
    )
  end
end
