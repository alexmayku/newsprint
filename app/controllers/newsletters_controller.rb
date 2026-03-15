class NewslettersController < ApplicationController
  MAX_PAGES = 32

  def index
    newsletters = current_user.newsletters.order(latest_issue_date: :desc)
    render inertia: "Newsletters/Index", props: {
      newsletters: newsletters.map { |n| serialize_newsletter(n) },
      maxPages: MAX_PAGES
    }
  end

  def create
    if params[:sender_email].blank?
      render json: { error: "sender_email is required" }, status: :unprocessable_entity
      return
    end

    newsletter = current_user.newsletters.find_or_initialize_by(sender_email: params[:sender_email])
    newsletter.assign_attributes(
      title: params[:title] || params[:sender_email],
      est_pages: params[:est_pages] || 4,
      latest_issue_date: params[:latest_issue_date] || Time.current
    )

    if newsletter.save
      render json: serialize_newsletter(newsletter), status: :created
    else
      render json: { errors: newsletter.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def discover
    job_id = SecureRandom.uuid
    ScanNewslettersJob.perform_later(current_user.id, job_id)
    render inertia: "Newsletters/Discovering", props: { jobId: job_id }
  end

  def discover_status
    redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
    status = redis.get("scan_job:#{params[:job_id]}") || "pending"
    render json: { status: status }
  end

  private

  def serialize_newsletter(newsletter)
    {
      id: newsletter.id,
      title: newsletter.title,
      sender_email: newsletter.sender_email,
      est_pages: newsletter.est_pages,
      latest_issue_date: newsletter.latest_issue_date&.iso8601,
      logo_url: newsletter.logo_url
    }
  end
end
