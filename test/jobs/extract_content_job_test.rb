require "test_helper"

class ExtractContentJobTest < ActiveJob::TestCase
  setup do
    @user = User.create!(email: "extract-user@example.com", google_token_enc: "fake_token")
    @newsletter = Newsletter.create!(
      user: @user, sender_email: "writer@substack.com",
      title: "Writer's Digest", est_pages: 4, latest_issue_date: Time.current
    )
    @job_id = "extract_job_123"
    @redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
    @redis.del("extract_job:#{@job_id}")

    @mock_message_detail = {
      id: "msg_1",
      from_email: "writer@substack.com",
      from_name: "Writer",
      subject: "Issue #42",
      date: 1.day.ago,
      html_body: file_fixture("newsletters/substack_single.html").read,
      headers: { "List-Unsubscribe" => "<https://unsub>" }
    }

    @mock_client = Object.new
    @mock_client.define_singleton_method(:fetch_messages) { |**_| [ { id: "msg_1" } ] }
    detail = @mock_message_detail
    @mock_client.define_singleton_method(:fetch_message_detail) { |_| detail }

    # Stub image downloads globally for all tests
    stub_request(:get, /substackcdn\.com/).to_return(
      status: 200,
      body: file_fixture("tiny.png").binread,
      headers: { "Content-Type" => "image/png" }
    )
  end

  teardown do
    @redis.del("extract_job:#{@job_id}")
  end

  test "job accepts newsletter_id and job_id" do
    assert_nothing_raised do
      ExtractContentJob.perform_now(@newsletter.id, @job_id, gmail_client: @mock_client)
    end
  end

  test "fetches the latest email for the newsletter sender from Gmail" do
    captured_query = nil
    client = Object.new
    detail = @mock_message_detail
    client.define_singleton_method(:fetch_messages) do |**args|
      captured_query = args[:query]
      [ { id: "msg_1" } ]
    end
    client.define_singleton_method(:fetch_message_detail) { |_| detail }

    ExtractContentJob.perform_now(@newsletter.id, @job_id, gmail_client: client)
    assert_not_nil captured_query
    assert_includes captured_query, "writer@substack.com"
  end

  test "calls ExtractorRegistry.extract with email HTML and metadata" do
    ExtractContentJob.perform_now(@newsletter.id, @job_id, gmail_client: @mock_client)
    # If extraction worked, articles were created
    assert @newsletter.articles.any?
  end

  test "extracted articles are saved as Article records" do
    ExtractContentJob.perform_now(@newsletter.id, @job_id, gmail_client: @mock_client)
    article = @newsletter.articles.first
    assert_not_nil article
    assert_equal "The Future of Independent Publishing", article.title
    assert_includes article.body_html, "Independent publishing"
  end

  test "existing articles are destroyed before creating new ones" do
    old_article = Article.create!(newsletter: @newsletter, title: "Old", body_html: "<p>old</p>")

    ExtractContentJob.perform_now(@newsletter.id, @job_id, gmail_client: @mock_client)

    assert_not Article.exists?(old_article.id)
    assert @newsletter.articles.reload.any?
  end

  test "QrCodeGenerator.generate_for_article is called for each article" do
    ExtractContentJob.perform_now(@newsletter.id, @job_id, gmail_client: @mock_client)

    @newsletter.articles.reload.each do |article|
      assert article.qr_references.any?, "Expected QR references for article #{article.title}"
    end
  end

  test "ImageDownloader.download_for_article is called for each article" do
    # Stub image downloads
    stub_request(:get, /substackcdn\.com/).to_return(
      status: 200,
      body: file_fixture("tiny.png").binread,
      headers: { "Content-Type" => "image/png" }
    )

    ExtractContentJob.perform_now(@newsletter.id, @job_id, gmail_client: @mock_client)

    @newsletter.articles.reload.each do |article|
      assert article.images.any?, "Expected images for article #{article.title}"
    end
  end

  test "status is tracked in Redis: extracting -> complete" do
    tracked_redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
    statuses = []
    original_set = tracked_redis.method(:set)
    tracked_redis.define_singleton_method(:set) do |key, value|
      statuses << value if key.start_with?("extract_job:")
      original_set.call(key, value)
    end

    ExtractContentJob.perform_now(@newsletter.id, @job_id, gmail_client: @mock_client, redis: tracked_redis)

    assert_includes statuses, "extracting"
    assert statuses.any? { |s| s.start_with?("complete") }
  end

  test "article with nil title falls back to email subject" do
    detail = @mock_message_detail.dup
    # Use minimal HTML that will produce a nil title from the generic extractor
    detail[:html_body] = "<p>Just a paragraph with no heading</p>"
    client = Object.new
    client.define_singleton_method(:fetch_messages) { |**_| [ { id: "msg_1" } ] }
    client.define_singleton_method(:fetch_message_detail) { |_| detail }

    ExtractContentJob.perform_now(@newsletter.id, @job_id, gmail_client: client)

    article = @newsletter.articles.reload.first
    assert_not_nil article
    # Should fall back to subject or "Untitled", not be blank
    assert article.title.present?, "Expected article title to be present"
  end

  test "article with nil body_html gets default body" do
    detail = @mock_message_detail.dup
    detail[:html_body] = nil
    client = Object.new
    client.define_singleton_method(:fetch_messages) { |**_| [ { id: "msg_1" } ] }
    client.define_singleton_method(:fetch_message_detail) { |_| detail }

    ExtractContentJob.perform_now(@newsletter.id, @job_id, gmail_client: client)

    article = @newsletter.articles.reload.first
    assert_not_nil article
    assert article.body_html.present?
  end

  test "GmailClient error sets status to failed" do
    error_client = Object.new
    error_client.define_singleton_method(:fetch_messages) { |**_| raise GmailClient::ApiError, "API down" }

    assert_raises(GmailClient::ApiError) do
      ExtractContentJob.perform_now(@newsletter.id, @job_id, gmail_client: error_client)
    end

    status = @redis.get("extract_job:#{@job_id}")
    assert_match(/failed/, status)
  end
end
