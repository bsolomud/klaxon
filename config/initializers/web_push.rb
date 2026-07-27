# Web Push (VAPID) configuration. Keys come from the environment so push works
# in production once set; when absent, push delivery is a no-op. Generate a pair
# with:  bin/rails runner 'pp WebPush.generate_key.to_h'
Rails.application.config.x.vapid = {
  subject: ENV.fetch("VAPID_SUBJECT", "mailto:noreply@aulabs.dev"),
  public_key: ENV["VAPID_PUBLIC_KEY"],
  private_key: ENV["VAPID_PRIVATE_KEY"]
}
