require "test_helper"

class NewspaperRendererTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email: "renderer@example.com")
    newsletter = Newsletter.create!(user: user, sender_email: "r@example.com",
                                    title: "Renderer Newsletter", est_pages: 4, latest_issue_date: Time.current)
    @article = Article.create!(
      newsletter: newsletter,
      title: "Test Article",
      author: "Jane Doe",
      body_html: '<p>Read <a href="https://example.com/link1">this article</a> and <a href="https://example.com/link2">this one</a></p>',
      link_urls: [ "https://example.com/link1", "https://example.com/link2" ]
    )
    QrCodeGenerator.generate_for_article(@article, offset: 0)

    @newspaper = Newspaper.create!(user: user, newsletters: [ newsletter ])
    @html = NewspaperRenderer.new(@newspaper).to_html
  end

  test "to_html returns a string containing DOCTYPE" do
    assert_includes @html, "<!DOCTYPE html>"
  end

  test "HTML includes a style block" do
    assert_includes @html, "<style"
    assert_includes @html, "</style>"
  end

  test "style block includes @page with size 280mm 400mm" do
    assert_match(/@page\s*\{[^}]*size:\s*280mm\s+400mm/, @html)
  end

  test "style block includes margin 15mm" do
    assert_match(/margin:\s*15mm/, @html)
  end

  test "style block includes .article break-before page" do
    assert_match(/\.article\s*\{[^}]*break-before:\s*page/, @html)
  end

  test "HTML includes a div with class front-page" do
    assert_match(/class="front-page"/, @html)
  end

  test "front page contains the newspaper title" do
    assert_includes @html, @newspaper.title
  end

  test "front page contains the date" do
    assert_includes @html, Date.current.strftime("%B %-d, %Y")
  end

  test "front page contains the edition number" do
    assert_includes @html, "Edition #{@newspaper.edition_number}"
  end

  # Part 2 tests

  test "each article appears in a section with class article" do
    assert_match(/<div class="article">/, @html)
  end

  test "article titles appear as h1 elements" do
    assert_match(/<h1>Test Article<\/h1>/, @html)
  end

  test "article author appears in a byline element" do
    assert_match(/class="byline".*Jane Doe/m, @html)
  end

  test "article body_html is included" do
    assert_includes @html, "this article"
  end

  test "links are unwrapped to plain text with QR superscript references" do
    assert_not_includes @html, "<a href="
    assert_match(/this article<sup class="qr-ref">\[1\]<\/sup>/, @html)
    assert_match(/this one<sup class="qr-ref">\[2\]<\/sup>/, @html)
  end

  test "links without QR references are unwrapped without superscript" do
    renderer = NewspaperRenderer.new(@newspaper)
    html = '<p>Visit <a href="https://no-qr.example.com">this site</a> for info</p>'
    result = renderer.prepare_body_for_print(html, @article.qr_references)

    assert_includes result, "Visit this site for info"
    assert_not_includes result, "<a "
    assert_not_includes result, "no-qr.example.com"
  end

  test "front page TOC lists each article title with its author" do
    assert_match(/Test Article.*Jane Doe/m, @html)
  end

  test "Links and References section appears with class qr-appendix" do
    assert_match(/class="qr-appendix"/, @html)
    assert_includes @html, "Links &amp; References"
  end

  test "each QR reference in appendix includes SVG, reference number, label, and URL" do
    assert_includes @html, "<svg"
    assert_match(/\[1\]/, @html)
    assert_includes @html, "link1"
    assert_includes @html, "https://example.com/link1"
  end

  test "QR codes in appendix use qr-grid CSS class" do
    assert_match(/class="qr-grid"/, @html)
  end
end
