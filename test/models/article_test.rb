require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "article-user@example.com")
    @newsletter = Newsletter.create!(user: @user, sender_email: "test@example.com",
                                     title: "Test Newsletter", est_pages: 4, latest_issue_date: Time.current)
  end

  def valid_attrs(overrides = {})
    {
      newsletter: @newsletter,
      title: "Article Title",
      body_html: "<p>Article body</p>"
    }.merge(overrides)
  end

  test "valid with all required fields" do
    article = Article.new(valid_attrs)
    assert article.valid?
  end

  test "title required" do
    article = Article.new(valid_attrs(title: nil))
    assert_not article.valid?
    assert_includes article.errors[:title], "can't be blank"
  end

  test "body_html required" do
    article = Article.new(valid_attrs(body_html: nil))
    assert_not article.valid?
    assert_includes article.errors[:body_html], "can't be blank"
  end

  test "belongs_to newsletter" do
    article = Article.create!(valid_attrs)
    assert_equal @newsletter, article.newsletter
  end

  test "position defaults to 0 and must be >= 0" do
    article = Article.create!(valid_attrs)
    assert_equal 0, article.position

    article.position = -1
    assert_not article.valid?

    article.position = 0
    assert article.valid?
  end

  test "image_urls stores and retrieves a text array" do
    urls = [ "https://example.com/a.png", "https://example.com/b.png" ]
    article = Article.create!(valid_attrs(image_urls: urls))
    article.reload
    assert_equal urls, article.image_urls
  end

  test "link_urls stores and retrieves a text array" do
    urls = [ "https://example.com/1", "https://example.com/2" ]
    article = Article.create!(valid_attrs(link_urls: urls))
    article.reload
    assert_equal urls, article.link_urls
  end

  test "dependent destroy deletes articles when newsletter is deleted" do
    Article.create!(valid_attrs)
    assert_difference "Article.count", -1 do
      @newsletter.destroy
    end
  end
end
