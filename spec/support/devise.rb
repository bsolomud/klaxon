RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request

  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  end
end
