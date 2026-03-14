require "test_helper"

class FixturesTest < ActiveSupport::TestCase
  test "all user fixtures are valid" do
    User.all.each do |user|
      assert user.valid?, "User #{user.email} is invalid: #{user.errors.full_messages.join(', ')}"
    end
  end

  test "all newsletter fixtures are valid" do
    Newsletter.all.each do |newsletter|
      assert newsletter.valid?, "Newsletter #{newsletter.title} is invalid: #{newsletter.errors.full_messages.join(', ')}"
    end
  end

  test "all order fixtures are valid" do
    Order.all.each do |order|
      assert order.valid?, "Order #{order.id} is invalid: #{order.errors.full_messages.join(', ')}"
    end
  end
end
