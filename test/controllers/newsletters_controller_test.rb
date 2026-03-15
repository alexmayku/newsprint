require "test_helper"

class NewslettersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:sarah)
    # Log in
    get "/auth/google_oauth2/callback"
  end

  test "GET /newsletters returns Inertia Newsletters/Index with newsletters and maxPages" do
    get newsletters_path
    assert_response :success
    # Inertia responses include the component name in the page JSON
    assert_includes response.body, "Newsletters/Index"
  end

  test "GET /newsletters requires authentication" do
    delete "/logout"
    get newsletters_path
    assert_redirected_to root_path
  end

  test "newsletters prop contains expected keys" do
    get newsletters_path
    assert_response :success
    # The Inertia page data is embedded as JSON in the response
    assert_includes response.body, "sender_email"
    assert_includes response.body, "est_pages"
    assert_includes response.body, "latest_issue_date"
  end

  test "maxPages is included in props" do
    get newsletters_path
    assert_response :success
    assert_includes response.body, "maxPages"
    assert_includes response.body, "32"
  end

  test "POST /newsletters/discover renders Discovering page with jobId" do
    post discover_newsletters_path

    assert_response :success
    assert_includes response.body, "Newsletters/Discovering"
    assert_includes response.body, "jobId"
  end

  test "GET /newsletters/discover/:job_id/status returns JSON with status from Redis" do
    redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
    redis.set("scan_job:test123", "detecting")

    get discover_status_newsletters_path(job_id: "test123")
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "detecting", json["status"]
  ensure
    redis&.del("scan_job:test123")
  end

  test "POST /newsletters with sender_email creates a Newsletter record" do
    assert_difference "Newsletter.count", 1 do
      post newsletters_path, params: { sender_email: "new@example.com" }
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "new@example.com", json["sender_email"]
  end

  test "POST /newsletters with blank sender_email returns error" do
    assert_no_difference "Newsletter.count" do
      post newsletters_path, params: { sender_email: "" }
    end

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json.key?("error")
  end
end
