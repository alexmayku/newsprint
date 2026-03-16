require "test_helper"

class QrCodeGeneratorTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email: "qr-gen@example.com")
    newsletter = Newsletter.create!(user: user, sender_email: "qr@example.com",
                                    title: "QR Test", est_pages: 4, latest_issue_date: Time.current)
    @article = Article.create!(
      newsletter: newsletter,
      title: "Test Article",
      body_html: "<p>body</p>",
      link_urls: [ "https://example.com/deep-dive", "https://research.org/paper?id=42&lang=en" ]
    )
  end

  test ".generate_svg returns a string starting with <svg" do
    svg = QrCodeGenerator.generate_svg("https://example.com")
    assert_includes svg, "<svg"
  end

  test "handles URLs with special characters" do
    svg = QrCodeGenerator.generate_svg("https://example.com/search?q=hello+world&page=1&sort=relevance")
    assert_includes svg, "<svg"
  end

  test "handles long URLs over 200 chars" do
    long_url = "https://example.com/" + "a" * 200
    svg = QrCodeGenerator.generate_svg(long_url)
    assert_includes svg, "<svg"
  end

  test ".generate_for_article creates QrReference records for each link_url" do
    assert_difference "QrReference.count", 2 do
      QrCodeGenerator.generate_for_article(@article, offset: 0)
    end
  end

  test "reference_numbers are sequential from offset+1" do
    records = QrCodeGenerator.generate_for_article(@article, offset: 5)
    assert_equal 6, records[0].reference_number
    assert_equal 7, records[1].reference_number
  end

  test "label is derived from URL last path segment or domain" do
    records = QrCodeGenerator.generate_for_article(@article, offset: 0)
    assert_equal "deep-dive", records[0].label
    assert_equal "paper", records[1].label
  end

  test "qr_svg is populated on each QrReference" do
    records = QrCodeGenerator.generate_for_article(@article, offset: 0)
    records.each do |record|
      assert_includes record.qr_svg, "<svg"
    end
  end

  test ".generate_svg returns nil for URLs exceeding QR capacity" do
    impossibly_long_url = "https://example.com/" + "a" * 10_000
    result = QrCodeGenerator.generate_svg(impossibly_long_url)
    assert_nil result
  end

  test ".generate_for_article skips URLs that exceed QR capacity" do
    article = Article.create!(
      newsletter: @article.newsletter,
      title: "Mixed URLs",
      body_html: "<p>body</p>",
      link_urls: [
        "https://example.com/short",
        "https://example.com/" + "a" * 10_000,
        "https://example.com/also-short"
      ]
    )

    records = QrCodeGenerator.generate_for_article(article, offset: 0)
    assert_equal 2, records.size
    assert_equal "https://example.com/short", records[0].url
    assert_equal "https://example.com/also-short", records[1].url
  end

  test ".generate_for_article keeps sequential reference numbers when skipping" do
    article = Article.create!(
      newsletter: @article.newsletter,
      title: "Sequential Test",
      body_html: "<p>body</p>",
      link_urls: [
        "https://example.com/first",
        "https://example.com/" + "a" * 10_000,
        "https://example.com/third"
      ]
    )

    records = QrCodeGenerator.generate_for_article(article, offset: 0)
    assert_equal 1, records[0].reference_number
    assert_equal 2, records[1].reference_number
  end
end
