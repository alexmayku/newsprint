require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "callback with valid OmniAuth mock creates a new user" do
    User.find_by(email: "sarah@example.com")&.destroy

    assert_difference "User.count", 1 do
      get "/auth/google_oauth2/callback"
    end

    user = User.find_by(email: "sarah@example.com")
    assert_not_nil user
  end

  test "callback finds existing user without creating a duplicate" do
    # sarah fixture already exists with this email
    assert_no_difference "User.count" do
      get "/auth/google_oauth2/callback"
    end
  end

  test "after callback user is redirected to /newsletters" do
    get "/auth/google_oauth2/callback"
    assert_redirected_to "/newsletters"
  end

  test "session user_id is set after successful callback" do
    get "/auth/google_oauth2/callback"
    user = User.find_by(email: "sarah@example.com")
    assert_equal user.id, session[:user_id]
  end

  test "DELETE /logout clears session and redirects to root" do
    get "/auth/google_oauth2/callback"
    assert_not_nil session[:user_id]

    delete "/logout"
    assert_redirected_to "/"
    assert_nil session[:user_id]
  end

  test "encrypted google_token_enc is stored from refresh_token" do
    get "/auth/google_oauth2/callback"
    user = User.find_by(email: "sarah@example.com")
    assert_equal "mock_refresh", user.google_token_enc
  end
end
