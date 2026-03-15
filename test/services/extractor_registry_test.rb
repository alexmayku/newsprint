require "test_helper"

class ExtractorRegistryTest < ActiveSupport::TestCase
  def metadata_for(email)
    { sender_email: email, sender_name: "Test", subject: "Test", date: Time.current }
  end

  test "sender @substack.com resolves to SubstackExtractor" do
    klass = ExtractorRegistry.extractor_for(metadata_for("writer@substack.com"))
    assert_equal Extractors::SubstackExtractor, klass
  end

  test "sender with domain containing mailchimp resolves to MailchimpExtractor" do
    klass = ExtractorRegistry.extractor_for(metadata_for("digest@mail.mailchimp.com"))
    assert_equal Extractors::MailchimpExtractor, klass
  end

  test "unknown sender resolves to GenericExtractor" do
    klass = ExtractorRegistry.extractor_for(metadata_for("hello@randomdomain.com"))
    assert_equal Extractors::GenericExtractor, klass
  end

  test ".extract calls the correct extractor and returns its result" do
    html = file_fixture("newsletters/substack_single.html").read
    meta = metadata_for("writer@substack.com")
    results = ExtractorRegistry.extract(html, meta)
    assert_kind_of Array, results
    assert_equal 1, results.size
    assert_equal "The Future of Independent Publishing", results.first[:title]
  end

  test "new extractors can be registered dynamically" do
    stub_class = Class.new(Extractors::BaseExtractor) do
      def extract
        [ { title: "ghost", author: nil, body_html: "", image_urls: [], link_urls: [] } ]
      end
    end

    ExtractorRegistry.register("ghost.io", stub_class)
    klass = ExtractorRegistry.extractor_for(metadata_for("author@ghost.io"))
    assert_equal stub_class, klass
  ensure
    ExtractorRegistry.deregister("ghost.io")
  end
end
