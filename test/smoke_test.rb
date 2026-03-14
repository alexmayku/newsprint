require "test_helper"

class SmokeTest < ActiveSupport::TestCase
  test "rails application is present" do
    assert_kind_of Rails::Application, Rails.application
  end
end
