require "test_helper"

class PageEstimatorTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "estimator@example.com")
  end

  def create_newsletter_with_articles(articles_data)
    newsletter = Newsletter.create!(user: @user, sender_email: "est-#{SecureRandom.hex(4)}@example.com",
                                    title: "Estimator Test", est_pages: 4, latest_issue_date: Time.current)
    articles_data.each do |data|
      Article.create!(
        newsletter: newsletter,
        title: data[:title] || "Article",
        body_html: data[:body_html] || "<p>#{'x' * 1000}</p>",
        image_urls: data[:image_urls] || [],
        link_urls: data[:link_urls] || []
      )
    end
    newsletter
  end

  test ".estimate returns a positive integer" do
    newsletter = create_newsletter_with_articles([ { body_html: "<p>#{'x' * 1000}</p>" } ])
    result = PageEstimator.estimate(newsletter)
    assert_kind_of Integer, result
    assert result > 0
  end

  test "more text equals more pages" do
    short = create_newsletter_with_articles([ { body_html: "<p>#{'x' * 1000}</p>" } ])
    long = create_newsletter_with_articles([ { body_html: "<p>#{'x' * 5000}</p>" } ])
    assert PageEstimator.estimate(long) > PageEstimator.estimate(short)
  end

  test "images add to the estimate" do
    no_images = create_newsletter_with_articles([ { body_html: "<p>#{'x' * 2000}</p>", image_urls: [] } ])
    with_images = create_newsletter_with_articles([ { body_html: "<p>#{'x' * 2000}</p>", image_urls: [ "a.jpg", "b.jpg", "c.jpg" ] } ])
    assert PageEstimator.estimate(with_images) > PageEstimator.estimate(no_images)
  end

  test "multiple articles add pages due to new-page rule" do
    three_articles = create_newsletter_with_articles([
      { body_html: "<p>short</p>" },
      { body_html: "<p>short</p>" },
      { body_html: "<p>short</p>" }
    ])
    assert PageEstimator.estimate(three_articles) >= 3
  end

  test "empty newsletter returns 1 minimum" do
    newsletter = Newsletter.create!(user: @user, sender_email: "empty@example.com",
                                    title: "Empty", est_pages: 1, latest_issue_date: Time.current)
    assert_equal 1, PageEstimator.estimate(newsletter)
  end

  test "QR appendix pages are included" do
    newsletter = create_newsletter_with_articles([
      { body_html: "<p>text</p>", link_urls: (1..10).map { |i| "https://example.com/link#{i}" } }
    ])
    # 10 links / 6 per page = 2 appendix pages
    estimate = PageEstimator.estimate(newsletter)
    # Should include at least 2 pages for the appendix
    no_links = create_newsletter_with_articles([ { body_html: "<p>text</p>", link_urls: [] } ])
    assert estimate >= PageEstimator.estimate(no_links) + 2
  end

  test "front page is counted" do
    newsletter = create_newsletter_with_articles([ { body_html: "<p>text</p>" } ])
    # Minimum: 1 front page + 1 article page = at least 2
    assert PageEstimator.estimate(newsletter) >= 2
  end

  test ".estimate_batch returns hash of newsletter_id to pages" do
    n1 = create_newsletter_with_articles([ { body_html: "<p>#{'x' * 1000}</p>" } ])
    n2 = create_newsletter_with_articles([ { body_html: "<p>#{'x' * 3000}</p>" } ])
    result = PageEstimator.estimate_batch([ n1, n2 ])
    assert_kind_of Hash, result
    assert_includes result.keys, n1.id
    assert_includes result.keys, n2.id
    assert_kind_of Integer, result[n1.id]
    assert_kind_of Integer, result[n2.id]
  end
end
