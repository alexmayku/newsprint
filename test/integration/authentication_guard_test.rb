require "test_helper"

class AuthenticationGuardTest < ActionDispatch::IntegrationTest
  test "unauthenticated user visiting /newsletters is redirected to root" do
    get "/newsletters"
    assert_redirected_to "/"
  end

  test "authenticated user can access /newsletters" do
    user = users(:sarah)
    post "/auth/google_oauth2/callback" # won't work, use OmniAuth
    get "/auth/google_oauth2/callback"

    get "/newsletters"
    assert_response :success
  end

  test "current_user returns the correct user when session is set" do
    get "/auth/google_oauth2/callback"
    user = User.find_by(email: "sarah@example.com")

    get "/newsletters"
    assert_equal user.id, session[:user_id]
  end

  test "current_user returns nil when session is empty" do
    get "/newsletters"
    assert_nil session[:user_id]
  end
end
