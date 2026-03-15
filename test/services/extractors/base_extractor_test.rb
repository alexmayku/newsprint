require "test_helper"

class Extractors::BaseExtractorTest < ActiveSupport::TestCase
  test "calling #extract raises NotImplementedError" do
    extractor = Extractors::BaseExtractor.new("<p>html</p>", {
      sender_email: "a@example.com", sender_name: "A", subject: "Sub", date: Time.current
    })
    assert_raises(NotImplementedError) { extractor.extract }
  end

  test ".new stores html and metadata" do
    html = "<h1>Hello</h1>"
    metadata = { sender_email: "a@example.com", sender_name: "A", subject: "Sub", date: Time.current }
    extractor = Extractors::BaseExtractor.new(html, metadata)
    assert_equal html, extractor.html
    assert_equal metadata, extractor.metadata
  end

  test "metadata must include sender_email, sender_name, subject, date" do
    assert_raises(ArgumentError) { Extractors::BaseExtractor.new("<p>html</p>", {}) }
    assert_raises(ArgumentError) { Extractors::BaseExtractor.new("<p>html</p>", { sender_email: "a@b.com" }) }

    valid = { sender_email: "a@example.com", sender_name: "A", subject: "Sub", date: Time.current }
    assert_nothing_raised { Extractors::BaseExtractor.new("<p>html</p>", valid) }
  end
end
