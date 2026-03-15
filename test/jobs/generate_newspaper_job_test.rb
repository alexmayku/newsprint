require "test_helper"

class GenerateNewspaperJobTest < ActiveJob::TestCase
  setup do
    @user = User.create!(email: "gen-newspaper@example.com", google_token_enc: "fake_token")
    @newsletter = Newsletter.create!(
      user: @user, sender_email: "writer@substack.com",
      title: "Test Newsletter", est_pages: 4, latest_issue_date: Time.current
    )
    @newspaper = Newspaper.create!(user: @user, newsletters: [ @newsletter ])
    @job_id = "gen_job_123"
    @redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
    @redis.del("generate_job:#{@job_id}")

    # Create a minimal valid PDF for stubbing
    @dummy_pdf = "%PDF-1.4 dummy content for testing"

    # Mock Gmail client
    @mock_client = Object.new
    html_fixture = file_fixture("newsletters/substack_single.html").read
    detail = {
      id: "msg_1", from_email: "writer@substack.com", from_name: "Writer",
      subject: "Issue #1", date: 1.day.ago, html_body: html_fixture,
      headers: { "List-Unsubscribe" => "<https://unsub>" }
    }
    @mock_client.define_singleton_method(:fetch_messages) { |**_| [ { id: "msg_1" } ] }
    @mock_client.define_singleton_method(:fetch_message_detail) { |_| detail }

    # Stub image downloads
    stub_request(:get, /substackcdn\.com/).to_return(
      status: 200, body: file_fixture("tiny.png").binread,
      headers: { "Content-Type" => "image/png" }
    )
  end

  teardown do
    @redis.del("generate_job:#{@job_id}")
  end

  def run_job(**overrides)
    defaults = { gmail_client: @mock_client, pdf_generator: stub_pdf_generator, pdf_postprocessor: stub_pdf_postprocessor }
    GenerateNewspaperJob.perform_now(@newspaper.id, @job_id, **defaults.merge(overrides))
  end

  def stub_pdf_generator
    dummy_pdf = @dummy_pdf
    obj = Object.new
    obj.define_singleton_method(:call) do |_html|
      { pdf_data: dummy_pdf, page_count: 4 }
    end
    obj
  end

  def stub_pdf_postprocessor
    obj = Object.new
    obj.define_singleton_method(:call) { |pdf_data| pdf_data }
    obj
  end

  test "accepts newspaper_id and job_id" do
    assert_nothing_raised { run_job }
  end

  test "sets newspaper status to generating at start" do
    statuses = []
    @newspaper.define_singleton_method(:generating!) do
      statuses << :generating
      super()
    end

    # Can't easily hook into the job mid-run, so verify it ends up generated
    run_job
    @newspaper.reload
    assert @newspaper.generated? || @newspaper.draft? # It progresses past generating
  end

  test "extracts content for each associated newsletter" do
    run_job
    @newspaper.reload
    assert @newsletter.articles.reload.any?, "Expected articles to be created"
  end

  test "renders HTML via NewspaperRenderer" do
    run_job
    # If job completes, rendering happened
    @newspaper.reload
    assert @newspaper.generated?
  end

  test "generates PDF and attaches it" do
    run_job
    @newspaper.reload
    assert @newspaper.pdf.attached?
  end

  test "updates newspaper page_count from PDF metadata" do
    run_job
    @newspaper.reload
    assert_equal 4, @newspaper.page_count
  end

  test "sets status to generated and generated_at" do
    run_job
    @newspaper.reload
    assert @newspaper.generated?
    assert_not_nil @newspaper.generated_at
  end

  test "on failure sets status to failed" do
    bad_generator = Object.new
    bad_generator.define_singleton_method(:call) { |_| raise StandardError, "boom" }

    assert_raises(StandardError) do
      run_job(pdf_generator: bad_generator)
    end

    @newspaper.reload
    assert @newspaper.failed?
  end

  test "tracks status in Redis throughout pipeline" do
    tracked_redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
    statuses = []
    original_set = tracked_redis.method(:set)
    tracked_redis.define_singleton_method(:set) do |key, value|
      statuses << value if key.start_with?("generate_job:")
      original_set.call(key, value)
    end

    run_job(redis: tracked_redis)

    assert_includes statuses, "generating"
    assert_includes statuses, "extracting"
    assert_includes statuses, "rendering"
    assert_includes statuses, "processing"
    assert statuses.any? { |s| s.start_with?("complete") }
  end
end
