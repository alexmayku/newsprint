require "test_helper"

class NewspaperTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "newspaper-user@example.com")
    @newsletter1 = Newsletter.create!(user: @user, sender_email: "a@example.com",
                                      title: "Newsletter A", est_pages: 4, latest_issue_date: Time.current)
    @newsletter2 = Newsletter.create!(user: @user, sender_email: "b@example.com",
                                      title: "Newsletter B", est_pages: 3, latest_issue_date: Time.current)
    Article.create!(newsletter: @newsletter1, title: "Art 1", body_html: "<p>a</p>")
    Article.create!(newsletter: @newsletter2, title: "Art 2", body_html: "<p>b</p>")
  end

  test "valid with required fields" do
    newspaper = Newspaper.new(user: @user)
    assert newspaper.valid?
  end

  test "belongs_to user" do
    newspaper = Newspaper.create!(user: @user)
    assert_equal @user, newspaper.user
  end

  test "title defaults to My Newsprint with current date" do
    newspaper = Newspaper.create!(user: @user)
    assert_equal "My Newsprint — #{Date.current.strftime('%B %-d, %Y')}", newspaper.title
  end

  test "status enum: draft, generating, generated, failed" do
    newspaper = Newspaper.create!(user: @user)
    assert newspaper.draft?

    newspaper.generating!
    assert newspaper.generating?

    newspaper.generated!
    assert newspaper.generated?

    newspaper.failed!
    assert newspaper.failed?
  end

  test "page_count is nullable" do
    newspaper = Newspaper.create!(user: @user, page_count: nil)
    assert_nil newspaper.page_count
  end

  test "edition_number is set automatically before create" do
    paper1 = Newspaper.create!(user: @user)
    assert_equal 1, paper1.edition_number

    paper2 = Newspaper.create!(user: @user)
    assert_equal 2, paper2.edition_number
  end

  test "newspaper can be associated with multiple newsletters via join table" do
    newspaper = Newspaper.create!(user: @user)
    newspaper.newsletters << @newsletter1
    newspaper.newsletters << @newsletter2
    assert_equal 2, newspaper.newsletters.count
  end

  test "newspaper.newsletters returns associated newsletters" do
    newspaper = Newspaper.create!(user: @user, newsletters: [ @newsletter1, @newsletter2 ])
    assert_includes newspaper.newsletters, @newsletter1
    assert_includes newspaper.newsletters, @newsletter2
  end

  test "newspaper.all_articles returns articles across associated newsletters" do
    newspaper = Newspaper.create!(user: @user, newsletters: [ @newsletter1, @newsletter2 ])
    assert_equal 2, newspaper.all_articles.count
    assert_includes newspaper.all_articles.map(&:title), "Art 1"
    assert_includes newspaper.all_articles.map(&:title), "Art 2"
  end

  test "has_one_attached pdf" do
    newspaper = Newspaper.create!(user: @user)
    assert_respond_to newspaper, :pdf
  end

  test "has_many orders" do
    newspaper = Newspaper.create!(user: @user)
    assert_respond_to newspaper, :orders
    assert_kind_of ActiveRecord::Associations::CollectionProxy, newspaper.orders
  end
end
