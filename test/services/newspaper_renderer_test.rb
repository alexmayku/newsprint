require "test_helper"

class NewspaperRendererTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email: "renderer@example.com")
    newsletter = Newsletter.create!(user: user, sender_email: "r@example.com",
                                    title: "Renderer Newsletter", est_pages: 4, latest_issue_date: Time.current)
    Article.create!(newsletter: newsletter, title: "Test Article", body_html: "<p>Content here</p>")

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
end
