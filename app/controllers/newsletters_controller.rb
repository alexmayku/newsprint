class NewslettersController < ApplicationController
  def index
    newsletters = current_user.newsletters.order(latest_issue_date: :desc)
    render inertia: "Newsletters/Index", props: {
      newsletters: newsletters.map { |n|
        {
          id: n.id,
          title: n.title,
          sender_email: n.sender_email,
          est_pages: n.est_pages,
          latest_issue_date: n.latest_issue_date&.iso8601,
          logo_url: n.logo_url
        }
      }
    }
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
end
