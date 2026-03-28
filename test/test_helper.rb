ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    def sign_in_admin(admin)
      post admin_session_path, params: {
        admin: { email: admin.email, password: "password" }
      }
    end

    setup do
      Geocoder::Lookup::Test.set_default_stub(
        [{ "latitude" => 50.4501, "longitude" => 30.5234 }]
      )
    end
  end
end
