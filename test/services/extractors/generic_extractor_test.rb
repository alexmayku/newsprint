require "test_helper"

class Extractors::GenericExtractorTest < ActiveSupport::TestCase
  setup do
    @metadata = {
      sender_email: "hello@morningbrief.com",
      sender_name: "The Morning Brief",
      subject: "Why Remote Work Is Here to Stay",
      date: Time.current
    }
  end

  def extract(fixture, metadata_overrides = {})
    html = file_fixture("newsletters/#{fixture}").read
    Extractors::GenericExtractor.new(html, @metadata.merge(metadata_overrides)).extract
  end

  test "finds the title from the first h1 in the generic fixture" do
    results = extract("generic_newsletter.html")
    assert_equal "Why Remote Work Is Here to Stay", results.first[:title]
  end

  test "falls back to metadata subject as title for minimal fixture" do
    results = extract("generic_minimal.html", subject: "Monthly Product Update")
    assert_equal "Monthly Product Update", results.first[:title]
  end

  test "body is the largest text block, not the nav or footer" do
    results = extract("generic_newsletter.html")
    body = results.first[:body_html]
    assert_includes body, "debate over remote work"
    assert_includes body, "Key takeaways"
    assert_not_includes body, "Copyright 2026"
    assert_not_includes body, "Unsubscribe"
  end

  test "author falls back to metadata sender_name" do
    results = extract("generic_minimal.html")
    assert_equal "The Morning Brief", results.first[:author]
  end

  test "returns exactly 1 article hash" do
    results = extract("generic_newsletter.html")
    assert_equal 1, results.size
    assert_kind_of Hash, results.first
  end

  test "images and links are extracted from the body" do
    results = extract("generic_newsletter.html")
    assert_includes results.first[:image_urls], "https://morningbrief.com/images/remote-work-stats.jpg"
    assert_includes results.first[:link_urls], "https://example.com/survey-results"
    assert_includes results.first[:link_urls], "https://example.com/urban-planning"
  end
end
