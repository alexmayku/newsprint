require "test_helper"

class NewsletterTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "owner@example.com")
  end

  def valid_attrs(overrides = {})
    {
      user: @user,
      sender_email: "news@example.com",
      title: "Weekly Digest",
      est_pages: 4,
      latest_issue_date: Time.current
    }.merge(overrides)
  end

  test "newsletter with all required fields is valid" do
    newsletter = Newsletter.new(valid_attrs)
    assert newsletter.valid?
  end

  test "sender_email is required" do
    newsletter = Newsletter.new(valid_attrs(sender_email: nil))
    assert_not newsletter.valid?
    assert_includes newsletter.errors[:sender_email], "can't be blank"
  end

  test "title is required" do
    newsletter = Newsletter.new(valid_attrs(title: nil))
    assert_not newsletter.valid?
    assert_includes newsletter.errors[:title], "can't be blank"
  end

  test "est_pages is required and must be a positive integer" do
    newsletter = Newsletter.new(valid_attrs(est_pages: nil))
    assert_not newsletter.valid?

    newsletter.est_pages = 0
    assert_not newsletter.valid?

    newsletter.est_pages = -1
    assert_not newsletter.valid?

    newsletter.est_pages = 2.5
    assert_not newsletter.valid?

    newsletter.est_pages = 3
    assert newsletter.valid?
  end

  test "latest_issue_date is required" do
    newsletter = Newsletter.new(valid_attrs(latest_issue_date: nil))
    assert_not newsletter.valid?
    assert_includes newsletter.errors[:latest_issue_date], "can't be blank"
  end

  test "newsletter.user returns the associated User" do
    newsletter = Newsletter.create!(valid_attrs)
    assert_equal @user, newsletter.user
  end

  test "deleting a user cascade-deletes their newsletters" do
    Newsletter.create!(valid_attrs)
    assert_difference "Newsletter.count", -1 do
      @user.destroy
    end
  end
end
