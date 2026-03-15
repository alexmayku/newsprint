class SessionsController < ApplicationController
  skip_before_action :require_authentication

  def create
    auth = request.env["omniauth.auth"]
    user = User.find_or_create_by!(email: auth.info.email)
    user.update!(google_token_enc: auth.credentials.refresh_token)
    session[:user_id] = user.id
    redirect_to newsletters_path
  end

  def destroy
    reset_session
    redirect_to root_path
  end
end
