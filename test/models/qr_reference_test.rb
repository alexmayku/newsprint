require "test_helper"

class QrReferenceTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email: "qr-user@example.com")
    newsletter = Newsletter.create!(user: user, sender_email: "qr@example.com",
                                    title: "QR Newsletter", est_pages: 4, latest_issue_date: Time.current)
    @article = Article.create!(newsletter: newsletter, title: "Article", body_html: "<p>body</p>")
  end

  def valid_attrs(overrides = {})
    { article: @article, url: "https://example.com/link", reference_number: 1, label: "Example Link" }.merge(overrides)
  end

  test "valid with all required fields" do
    assert QrReference.new(valid_attrs).valid?
  end

  test "url required" do
    qr = QrReference.new(valid_attrs(url: nil))
    assert_not qr.valid?
    assert_includes qr.errors[:url], "can't be blank"
  end

  test "reference_number required and positive integer" do
    qr = QrReference.new(valid_attrs(reference_number: nil))
    assert_not qr.valid?

    qr.reference_number = 0
    assert_not qr.valid?

    qr.reference_number = -1
    assert_not qr.valid?

    qr.reference_number = 2.5
    assert_not qr.valid?

    qr.reference_number = 1
    assert qr.valid?
  end

  test "label required" do
    qr = QrReference.new(valid_attrs(label: nil))
    assert_not qr.valid?
    assert_includes qr.errors[:label], "can't be blank"
  end

  test "belongs_to article" do
    qr = QrReference.create!(valid_attrs)
    assert_equal @article, qr.article
  end

  test "qr_svg is optional" do
    qr = QrReference.new(valid_attrs(qr_svg: nil))
    assert qr.valid?
  end

  test "dependent destroy deletes qr_references when article is deleted" do
    QrReference.create!(valid_attrs)
    assert_difference "QrReference.count", -1 do
      @article.destroy
    end
  end
end
