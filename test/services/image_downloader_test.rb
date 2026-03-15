require "test_helper"

class ImageDownloaderTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email: "img-dl@example.com")
    newsletter = Newsletter.create!(user: user, sender_email: "img@example.com",
                                    title: "Img Test", est_pages: 4, latest_issue_date: Time.current)
    @article = Article.create!(
      newsletter: newsletter,
      title: "Test Article",
      body_html: "<p>body</p>",
      image_urls: [
        "https://cdn.example.com/photo1.png",
        "https://cdn.example.com/photo2.png"
      ]
    )

    @png_data = file_fixture("tiny.png").binread

    stub_request(:get, "https://cdn.example.com/photo1.png")
      .to_return(status: 200, body: @png_data, headers: { "Content-Type" => "image/png" })
    stub_request(:get, "https://cdn.example.com/photo2.png")
      .to_return(status: 200, body: @png_data, headers: { "Content-Type" => "image/png" })
  end

  test "downloads each URL and attaches via ActiveStorage" do
    ImageDownloader.download_for_article(@article)
    assert_equal 2, @article.images.count
  end

  test "failed downloads are logged but do not raise" do
    @article.update!(image_urls: [ "https://cdn.example.com/missing.png" ])
    stub_request(:get, "https://cdn.example.com/missing.png").to_return(status: 404)

    assert_nothing_raised do
      ImageDownloader.download_for_article(@article)
    end
    assert_equal 0, @article.images.count
  end

  test "duplicate URLs are not downloaded twice" do
    @article.update!(image_urls: [
      "https://cdn.example.com/photo1.png",
      "https://cdn.example.com/photo1.png"
    ])
    ImageDownloader.download_for_article(@article)
    assert_equal 1, @article.images.count
  end

  test ".image_meets_print_dpi? returns true for sufficiently large image" do
    large_data = file_fixture("large.png").binread
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(large_data), filename: "large.png", content_type: "image/png"
    )
    # 800px wide at 130mm target = 800 / (130/25.4) = ~156 DPI >= 150
    assert ImageDownloader.image_meets_print_dpi?(blob, target_width_mm: 130)
  end

  test ".image_meets_print_dpi? returns false for tiny image" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(@png_data), filename: "tiny.png", content_type: "image/png"
    )
    # 2px wide at 130mm = ~0.4 DPI
    assert_not ImageDownloader.image_meets_print_dpi?(blob, target_width_mm: 130)
  end
end
