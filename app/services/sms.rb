# Pluggable SMS gateway. The default LogAdapter performs no external calls; set
# Sms.adapter to a Twilio/TurboSMS adapter once provider credentials exist.
module Sms
  class LogAdapter
    def deliver(to:, body:)
      Rails.logger.info("[SMS -> #{to}] #{body}")
    end
  end

  mattr_accessor :adapter, default: LogAdapter.new

  def self.deliver(to:, body:)
    return if to.blank?

    adapter.deliver(to: to, body: body)
  end
end
