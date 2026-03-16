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

  test "inline style attributes are stripped from all elements" do
    html = <<~HTML
      <p style="color: red; font-size: 14px;">Styled paragraph</p>
      <div style="background: blue;"><span style="font-weight: bold;">Styled span</span></div>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "Styled paragraph"
    assert_includes result, "Styled span"
    assert_not_includes result, "style="
  end

  test "class attributes are stripped from all elements" do
    html = <<~HTML
      <p class="email-body mc-content">Content with classes</p>
      <div class="wrapper"><span class="highlight">Classed span</span></div>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "Content with classes"
    assert_includes result, "Classed span"
    assert_not_includes result, "class="
  end

  test "horizontal rules are removed" do
    html = <<~HTML
      <p>Before</p>
      <hr>
      <hr/>
      <p>After</p>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "Before"
    assert_includes result, "After"
    assert_not_includes result, "<hr"
  end

  test "CTA buttons are removed" do
    html = <<~HTML
      <p>Real content</p>
      <p><a href="https://example.com/more">Read more</a></p>
      <p><a href="https://example.com/sub">Subscribe</a></p>
      <p><a href="https://example.com/share">Share this →</a></p>
      <p><a href="https://example.com/view">View online</a></p>
      <p><a href="https://example.com/start">Get started</a></p>
      <p><a href="https://example.com/learn">Learn more</a></p>
      <p><a href="https://example.com/signup">Sign up</a></p>
      <p><a href="https://example.com/dl">Download</a></p>
      <p><a href="https://example.com/shop">Shop now</a></p>
      <p><a href="https://example.com/click">Click here</a></p>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "Real content"
    assert_not_includes result, "Read more"
    assert_not_includes result, "Subscribe"
    assert_not_includes result, "Share this"
    assert_not_includes result, "View online"
    assert_not_includes result, "Get started"
    assert_not_includes result, "Learn more"
    assert_not_includes result, "Sign up"
    assert_not_includes result, "Download"
    assert_not_includes result, "Shop now"
    assert_not_includes result, "Click here"
  end

  test "CTA removal does not affect regular contextual links" do
    html = <<~HTML
      <p>Read <a href="https://example.com/article">this article about learning more</a> for details</p>
      <p>You can <a href="https://example.com/download/report.pdf">download the full report here</a></p>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "this article about learning more"
    assert_includes result, "download the full report here"
  end

  test "expanded CTAs are removed: read in app, upgrade, subscribe here, start writing" do
    html = <<~HTML
      <p>Real content</p>
      <p><a href="https://example.com/app">Read in app</a></p>
      <p><a href="https://example.com/upgrade">Upgrade to paid</a></p>
      <p><a href="https://example.com/upgrade">Upgrade</a></p>
      <p><a href="https://example.com/sub">Subscribe here</a></p>
      <p><a href="https://example.com/write">Start writing</a></p>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "Real content"
    assert_not_includes result, "Read in app"
    assert_not_includes result, "Upgrade to paid"
    assert_not_includes result, "Upgrade"
    assert_not_includes result, "Subscribe here"
    assert_not_includes result, "Start writing"
  end

  test "forwarded email banners are removed" do
    html = <<~HTML
      <div><span>Forwarded this email? <a href="https://example.com/sub">Subscribe here</a> for more</span></div>
      <p>Real content</p>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "Real content"
    assert_not_includes result, "Forwarded this email"
  end

  test "forwarded email banner removal does not destroy parent containers with content" do
    html = <<~HTML
      <div>
        <table><tbody><tr><td><span>Forwarded this email? <a href="https://example.com">Subscribe here</a></span></td></tr></tbody></table>
        <p>This is the actual article content that must survive.</p>
        <p>And this is another paragraph of real content.</p>
      </div>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "actual article content"
    assert_includes result, "another paragraph"
    assert_not_includes result, "Forwarded this email"
  end

  test "platform post header regions are removed" do
    html = <<~HTML
      <div role="region" aria-label="Post header">
        <h1><a href="https://example.com">Article Title</a></h1>
        <h3>Subtitle</h3>
        <div>Author Name</div>
        <div>Mar 15 · Preview</div>
      </div>
      <p>Real article content</p>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "Real article content"
    assert_not_includes result, "Post header"
    assert_not_includes result, "Preview"
  end

  test "paywall blocks are removed" do
    html = <<~HTML
      <p>Real content before paywall</p>
      <div data-testid="paywall" data-component-name="Paywall">
        <h2>Subscribe to Newsletter to unlock the rest.</h2>
        <p>Become a paying subscriber to get access to this post.</p>
        <a href="https://example.com/upgrade">Upgrade to paid</a>
      </div>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "Real content before paywall"
    assert_not_includes result, "unlock the rest"
    assert_not_includes result, "paying subscriber"
  end

  test "platform engagement links are removed" do
    html = <<~HTML
      <p>Real content</p>
      <table><tbody><tr>
        <td><a href="https://substack.com/app-link/post?submitLike=true"><img src="heart.png" width="18" height="18"></a></td>
        <td><a href="https://substack.com/app-link/post?comments=true"><img src="comment.png" width="18" height="18"></a></td>
      </tr></tbody></table>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "Real content"
    assert_not_includes result, "substack.com/app-link"
  end

  test "platform icon and button images are removed" do
    html = <<~HTML
      <p>Real content</p>
      <a href="https://example.com"><img src="https://substackcdn.com/icon/LucideHeart" width="18" height="18"></a>
      <a href="https://example.com"><img src="https://substackcdn.com/img/email/publish-button.png" width="135" height="40"></a>
      <img src="https://example.com/real-photo.jpg" width="600">
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "Real content"
    assert_includes result, "real-photo.jpg"
    assert_not_includes result, "substackcdn.com/icon"
    assert_not_includes result, "publish-button"
  end

  test "subscription pitch sections are removed" do
    html = <<~HTML
      <p>Real content</p>
      <div>
        <h3>A subscription gets you:</h3>
        <table><tbody>
          <tr><td>Subscriber-only posts</td></tr>
          <tr><td>Post comments</td></tr>
        </tbody></table>
      </div>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "Real content"
    assert_not_includes result, "subscription gets you"
    assert_not_includes result, "Subscriber-only"
  end

  test "preheader invisible text is removed" do
    html = <<~HTML
      <div>\u034F     \u00AD\u034F     \u00AD\u034F     \u00AD</div>
      <p>Real content</p>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "Real content"
    refute_match(/\u034F/, result)
  end

  test "data attributes are stripped" do
    html = <<~HTML
      <div data-component-name="Image" data-attrs='{"src":"test.jpg"}'>
        <img src="test.jpg" width="400">
      </div>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "test.jpg"
    assert_not_includes result, "data-component-name"
    assert_not_includes result, "data-attrs"
  end

  test "empty table elements are cleaned up after chrome removal" do
    html = <<~HTML
      <p>Real content</p>
      <table><tbody><tr><td></td><td>  </td></tr></tbody></table>
    HTML

    result = Extractors::HtmlSanitiser.sanitise(html)
    assert_includes result, "Real content"
    refute_match(/<table>\s*<\/table>/, result)
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
