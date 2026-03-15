class NewspapersController < ApplicationController
  def create
    newspaper = current_user.newspapers.create!
    newsletter_ids = params[:newsletter_ids] || []
    newspaper.newsletter_ids = newsletter_ids
    redirect_to newsletters_path
  end
end
