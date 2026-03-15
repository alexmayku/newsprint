require "test_helper"

class Extractors::MailchimpExtractorTest < ActiveSupport::TestCase
  setup do
    @html = file_fixture("newsletters/mailchimp_digest.html").read
    @metadata = {
      sender_email: "digest@mail.mailchimp.com",
      sender_name: "Design Weekly",
      subject: "Design Weekly #42",
      date: Time.current
    }
    @extractor = Extractors::MailchimpExtractor.new(@html, @metadata)
    @results = @extractor.extract
  end

  test "returns an array with 2 article hashes" do
    assert_equal 2, @results.size
    @results.each { |r| assert_kind_of Hash, r }
  end

  test "each article has a title extracted from its h2" do
    assert_equal "The Rise of Variable Fonts", @results[0][:title]
    assert_equal "Designing for Accessibility in 2026", @results[1][:title]
  end

  test "Mailchimp footer, badge, and tracking elements are stripped" do
    @results.each do |article|
      assert_not_includes article[:body_html], "Unsubscribe"
      assert_not_includes article[:body_html], "Powered by Mailchimp"
      assert_not_includes article[:body_html], "pixel.gif"
      assert_not_includes article[:body_html], "Update preferences"
    end
  end

  test "images from content blocks are captured" do
    assert_includes @results[0][:image_urls], "https://cdn.mailchimp.com/images/variable-fonts-demo.jpg"
    assert_includes @results[1][:image_urls], "https://cdn.mailchimp.com/images/accessibility-guide.png"
  end

  test "Mailchimp tracking redirect URLs are captured as-is" do
    assert @results[0][:link_urls].any? { |u| u.include?("mailchimp.com/track/click") }
    assert @results[1][:link_urls].any? { |u| u.include?("mailchimp.com/track/click") }
  end
end
