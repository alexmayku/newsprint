require "test_helper"

class ScanNewslettersJobTest < ActiveJob::TestCase
  setup do
    @user = User.create!(email: "scan-user@example.com", google_token_enc: "fake_token")
    @job_id = "test_job_123"
    @redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
    @redis.del("scan_job:#{@job_id}")

    @message_ids = [ { id: "msg_1" }, { id: "msg_2" }, { id: "msg_3" } ]
    @message_details = [
      { id: "msg_1", from_email: "writer@substack.com", from_name: "Writer", subject: "Issue 1",
        date: 1.day.ago, html_body: "<p>hello</p>", headers: { "List-Unsubscribe" => "<https://unsub>" } },
      { id: "msg_2", from_email: "writer@substack.com", from_name: "Writer", subject: "Issue 2",
        date: 2.days.ago, html_body: "<p>hello</p>", headers: { "List-Unsubscribe" => "<https://unsub>" } },
      { id: "msg_3", from_email: "writer@substack.com", from_name: "Writer", subject: "Issue 3",
        date: 3.days.ago, html_body: "<p>hello</p>", headers: { "List-Unsubscribe" => "<https://unsub>" } }
    ]
  end

  teardown do
    @redis.del("scan_job:#{@job_id}")
    @redis.del("scan_job:job_2")
  end

  test "job calls GmailClient#fetch_messages with appropriate query" do
    fetch_called = false
    mock_client = build_mock_client(
      on_fetch_messages: ->(**args) {
        fetch_called = true
        assert_match(/newer_than/, args[:query])
        @message_ids
      }
    )

    ScanNewslettersJob.perform_now(@user.id, @job_id, gmail_client: mock_client)
    assert fetch_called
  end

  test "job scans only the last 30 days" do
    captured_query = nil
    mock_client = build_mock_client(
      on_fetch_messages: ->(**args) {
        captured_query = args[:query]
        @message_ids
      }
    )

    ScanNewslettersJob.perform_now(@user.id, @job_id, gmail_client: mock_client)
    assert_includes captured_query, "newer_than:30d"
  end

  test "job passes messages to NewsletterDetector" do
    mock_client = build_mock_client
    ScanNewslettersJob.perform_now(@user.id, @job_id, gmail_client: mock_client)

    # If detection worked, newsletters were created
    assert Newsletter.exists?(user: @user, sender_email: "writer@substack.com")
  end

  test "detected newsletters are upserted as Newsletter records" do
    mock_client = build_mock_client

    assert_difference "Newsletter.count", 1 do
      ScanNewslettersJob.perform_now(@user.id, @job_id, gmail_client: mock_client)
    end

    newsletter = Newsletter.find_by(user: @user, sender_email: "writer@substack.com")
    assert_not_nil newsletter
    assert_equal "Writer", newsletter.title
  end

  test "running twice does NOT create duplicates" do
    mock_client = build_mock_client

    ScanNewslettersJob.perform_now(@user.id, @job_id, gmail_client: mock_client)

    assert_no_difference "Newsletter.count" do
      ScanNewslettersJob.perform_now(@user.id, "job_2", gmail_client: mock_client)
    end
  end

  test "existing newsletters get updated est_pages and latest_issue_date on re-scan" do
    Newsletter.create!(user: @user, sender_email: "writer@substack.com", title: "Old Title",
                       est_pages: 2, latest_issue_date: 30.days.ago)

    mock_client = build_mock_client
    ScanNewslettersJob.perform_now(@user.id, @job_id, gmail_client: mock_client)

    newsletter = Newsletter.find_by(user: @user, sender_email: "writer@substack.com")
    assert newsletter.latest_issue_date > 30.days.ago
    assert newsletter.est_pages > 0
  end

  test "job tracks status in Redis through scanning -> detecting -> complete" do
    statuses = []
    tracked_redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
    original_set = tracked_redis.method(:set)
    tracked_redis.define_singleton_method(:set) do |key, value|
      statuses << value if key.start_with?("scan_job:")
      original_set.call(key, value)
    end

    mock_client = build_mock_client
    ScanNewslettersJob.perform_now(@user.id, @job_id, gmail_client: mock_client, redis: tracked_redis)

    assert_includes statuses, "scanning"
    assert_includes statuses, "detecting"
    assert statuses.any? { |s| s.start_with?("complete") }
  end

  test "if GmailClient raises an error status is set to failed and error is re-raised" do
    error_client = Object.new
    error_client.define_singleton_method(:fetch_messages) { |**_| raise GmailClient::ApiError, "API down" }

    assert_raises(GmailClient::ApiError) do
      ScanNewslettersJob.perform_now(@user.id, @job_id, gmail_client: error_client)
    end

    status = @redis.get("scan_job:#{@job_id}")
    assert_match(/failed/, status)
  end

  test "job is performed in the default queue" do
    assert_equal "default", ScanNewslettersJob.new.queue_name
  end

  private

  def build_mock_client(on_fetch_messages: nil)
    message_ids = @message_ids
    message_details = @message_details

    client = Object.new
    client.define_singleton_method(:fetch_messages) do |**args|
      on_fetch_messages ? on_fetch_messages.call(**args) : message_ids
    end
    client.define_singleton_method(:fetch_message_detail) do |msg_id|
      message_details.find { |m| m[:id] == msg_id }
    end
    client
  end
end
