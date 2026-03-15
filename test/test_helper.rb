ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/reporters"
require "webmock/minitest"

Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new

WebMock.disable_net_connect!(allow_localhost: true)

OmniAuth.config.test_mode = true
OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
  provider: "google_oauth2", uid: "123456",
  info: { email: "sarah@example.com", name: "Sarah" },
  credentials: { token: "mock_token", refresh_token: "mock_refresh" }
})

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors, threshold: 500)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
