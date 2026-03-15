require "test_helper"

class Extractors::HtmlSanitiserTest < ActiveSupport::TestCase
  test "tracking pixels are removed" do
    html = <<~HTML
      <p>Content</p>
      <img src="https://track.example.com/open.gif" width="1" height="1">
      <img src="https://example.com/pixel.png">
      <img src="https://example.com/tracking?id=123">
      <img src="https://example.com/real-image.jpg" width="600">
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_not_includes result, "track.example.com"
    assert_not_includes result, "pixel.png"
    assert_not_includes result, "tracking?id=123"
    assert_includes result, "real-image.jpg"
  end

  test "unsubscribe links and surrounding paragraphs are removed" do
    html = <<~HTML
      <p>Real content here</p>
      <p><a href="https://example.com/unsubscribe">Unsubscribe</a></p>
      <p>You received this because you signed up. <a href="#">Unsubscribe here</a>.</p>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "Real content here"
    assert_not_includes result, "Unsubscribe"
    assert_not_includes result, "unsubscribe"
  end

  test "script and style tags are removed" do
    html = <<~HTML
      <p>Content</p>
      <script>alert('xss')</script>
      <style>.body { color: red; }</style>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "Content"
    assert_not_includes result, "alert"
    assert_not_includes result, "color: red"
  end

  test "empty paragraphs and divs are removed" do
    html = <<~HTML
      <p>Real content</p>
      <p></p>
      <p>   </p>
      <div></div>
      <div>  </div>
      <p>More content</p>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "Real content"
    assert_includes result, "More content"
    # Should not have empty p or div tags
    refute_match(/<p>\s*<\/p>/, result)
    refute_match(/<div>\s*<\/div>/, result)
  end

  test "valid content is preserved" do
    html = <<~HTML
      <h1>Heading</h1>
      <p>Paragraph with <a href="https://example.com">a link</a></p>
      <img src="https://example.com/photo.jpg" width="400">
      <blockquote>A quote</blockquote>
      <ul><li>Item one</li><li>Item two</li></ul>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "<h1>Heading</h1>"
    assert_includes result, "a link"
    assert_includes result, "photo.jpg"
    assert_includes result, "A quote"
    assert_includes result, "Item one"
  end

  test "view in browser links are removed" do
    html = <<~HTML
      <p><a href="https://example.com/view">View in browser</a></p>
      <p><a href="https://example.com/view">View this email in your browser</a></p>
      <p>Real content</p>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_not_includes result, "View in browser"
    assert_not_includes result, "View this email"
    assert_includes result, "Real content"
  end

  test "social media footer icons and links are removed" do
    html = <<~HTML
      <p>Real content</p>
      <p><a href="https://twitter.com/example"><img src="twitter-icon.png"></a>
         <a href="https://facebook.com/example"><img src="facebook-icon.png"></a>
         <a href="https://instagram.com/example"><img src="instagram-icon.png"></a></p>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "Real content"
    assert_not_includes result, "twitter.com"
    assert_not_includes result, "facebook.com"
    assert_not_includes result, "instagram.com"
  end
end
