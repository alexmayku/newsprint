class PagesController < ApplicationController
  skip_before_action :require_authentication

  def home
    redirect_to newsletters_path if logged_in?
  end
end
