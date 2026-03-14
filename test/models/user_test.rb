require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "user with valid email is valid" do
    user = User.new(email: "test@example.com")
    assert user.valid?
  end

  test "user without email is invalid" do
    user = User.new(email: nil)
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "duplicate emails are rejected case-insensitively" do
    User.create!(email: "dupe@example.com")
    user = User.new(email: "DUPE@example.com")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "delivery_address stores and retrieves a JSON hash" do
    address = { "line1" => "123 Main St", "city" => "London", "postcode" => "SW1A 1AA", "country" => "GB" }
    user = User.create!(email: "address@example.com", delivery_address: address)
    user.reload
    assert_equal address, user.delivery_address
  end

  test "google_token_enc can be written and read back via encrypted attributes" do
    token = '{"access_token":"ya29.abc","refresh_token":"1//xyz"}'
    user = User.create!(email: "token@example.com", google_token_enc: token)
    user.reload
    assert_equal token, user.google_token_enc
  end

  test "stripe_customer_id is optional" do
    user = User.new(email: "stripe@example.com", stripe_customer_id: nil)
    assert user.valid?
  end

  test "user.newsletters returns a collection" do
    user = User.create!(email: "newsletters@example.com")
    assert_respond_to user, :newsletters
    assert_kind_of ActiveRecord::Associations::CollectionProxy, user.newsletters
  end

  test "user.newsletters.count is correct after creating newsletters" do
    user = User.create!(email: "count@example.com")
    assert_equal 0, user.newsletters.count
    Newsletter.create!(user: user, sender_email: "a@example.com", title: "A", est_pages: 2, latest_issue_date: Time.current)
    Newsletter.create!(user: user, sender_email: "b@example.com", title: "B", est_pages: 3, latest_issue_date: Time.current)
    assert_equal 2, user.newsletters.count
  end
end
