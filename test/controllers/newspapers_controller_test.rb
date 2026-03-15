require "test_helper"

class NewspapersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:sarah)
    @newsletter = newsletters(:substack_one)
    # Log in
    get "/auth/google_oauth2/callback"
  end

  test "POST /newspapers with valid newsletter_ids creates newspaper and redirects to preview" do
    assert_difference "Newspaper.count", 1 do
      post newspapers_path, params: { newsletter_ids: [ @newsletter.id ] }
    end

    newspaper = Newspaper.last
    assert_includes newspaper.newsletter_ids, @newsletter.id
    assert_redirected_to preview_newspaper_path(newspaper)
  end

  test "POST /newspapers with empty newsletter_ids returns error" do
    assert_no_difference "Newspaper.count" do
      post newspapers_path, params: { newsletter_ids: [] }
    end

    assert_response :unprocessable_entity
  end

  test "POST /newspapers requires authentication" do
    delete "/logout"
    post newspapers_path, params: { newsletter_ids: [ @newsletter.id ] }
    assert_redirected_to root_path
  end

  test "GET /newspapers/:id/status returns JSON with status from Redis" do
    newspaper = Newspaper.create!(user: @user)
    redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
    redis.set("generate_job:newspaper_#{newspaper.id}", "rendering")

    get status_newspaper_path(newspaper)
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "rendering", json["status"]
  ensure
    redis&.del("generate_job:newspaper_#{newspaper.id}")
  end

  test "GET /newspapers/:id/preview renders Inertia Newspapers/Preview" do
    newspaper = Newspaper.create!(user: @user, newsletters: [ @newsletter ])

    get preview_newspaper_path(newspaper)
    assert_response :success
    assert_includes response.body, "Newspapers/Preview"
  end

  test "GET /newspapers/:id/preview for another users newspaper returns 404" do
    other_user = users(:james)
    newspaper = Newspaper.create!(user: other_user)

    get preview_newspaper_path(newspaper)
    assert_response :not_found
  end

  test "GET /newspapers/:id/pdf redirects to ActiveStorage URL when PDF exists" do
    newspaper = Newspaper.create!(user: @user)
    newspaper.pdf.attach(
      io: StringIO.new("%PDF-1.4 test"),
      filename: "test.pdf",
      content_type: "application/pdf"
    )

    get pdf_newspaper_path(newspaper)
    assert_response :redirect
  end

  test "GET /newspapers/:id/pdf returns 404 when no PDF attached" do
    newspaper = Newspaper.create!(user: @user)

    get pdf_newspaper_path(newspaper)
    assert_response :not_found
  end
end
