class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "AULABS <no-reply@aulabs.app>")
  layout "mailer"
end
