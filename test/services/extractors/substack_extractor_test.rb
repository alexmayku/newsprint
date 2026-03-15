require "test_helper"

class Extractors::SubstackExtractorTest < ActiveSupport::TestCase
  setup do
    @html = file_fixture("newsletters/substack_single.html").read
    @metadata = {
      sender_email: "writer@substack.com",
      sender_name: "The Writer's Digest",
      subject: "The Future of Independent Publishing",
      date: Time.current
    }
    @extractor = Extractors::SubstackExtractor.new(@html, @metadata)
    @results = @extractor.extract
    @article = @results.first
  end

  test "extracts the article title from h1" do
    assert_equal "The Future of Independent Publishing", @article[:title]
  end

  test "extracts the author from the byline element" do
    assert_equal "Sarah Chen", @article[:author]
  end

  test "body_html contains paragraphs, blockquote, and list" do
    assert_includes @article[:body_html], "Independent publishing has changed"
    assert_includes @article[:body_html], "best writing happens"
    assert_includes @article[:body_html], "Direct monetization"
  end

  test "body_html does NOT contain the footer or tracking pixel" do
    assert_not_includes @article[:body_html], "You're receiving this"
    assert_not_includes @article[:body_html], "Unsubscribe"
    assert_not_includes @article[:body_html], "pixel.gif"
  end

  test "image_urls contains the body image but not the tracking pixel" do
    assert_includes @article[:image_urls], "https://substackcdn.com/image/fetch/publishing-chart.jpg"
    refute @article[:image_urls].any? { |u| u.include?("pixel") }
  end

  test "link_urls contains the two hyperlinks but not unsubscribe or header links" do
    assert_includes @article[:link_urls], "https://example.com/publishing-trends"
    assert_includes @article[:link_urls], "https://example.com/future-of-writing"
    refute @article[:link_urls].any? { |u| u.include?("unsubscribe") }
    refute @article[:link_urls].any? { |u| u.include?("substack.com") && !u.include?("example.com") }
  end

  test "returns an array with exactly 1 article hash" do
    assert_equal 1, @results.size
    assert_kind_of Hash, @article
  end
end
