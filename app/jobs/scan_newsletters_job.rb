class ScanNewslettersJob < ApplicationJob
  queue_as :default

  def perform(user_id, job_id, gmail_client: nil, redis: nil)
    user = User.find(user_id)
    redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))

    redis.set("scan_job:#{job_id}", "scanning")

    client = gmail_client || GmailClient.new(user)
    message_ids = client.fetch_messages(query: "newer_than:90d", max_results: 200)

    message_details = message_ids.map { |m| client.fetch_message_detail(m[:id]) }

    redis.set("scan_job:#{job_id}", "detecting")

    detector = NewsletterDetector.new(message_details)
    detected = detector.detect

    detected.each do |result|
      newsletter = Newsletter.find_or_initialize_by(user: user, sender_email: result[:sender_email])
      newsletter.assign_attributes(
        title: result[:sender_name],
        est_pages: result[:message_count],
        latest_issue_date: result[:latest_date]
      )
      newsletter.save!
    end

    redis.set("scan_job:#{job_id}", "complete:#{detected.size}")
  rescue GmailClient::ApiError => e
    redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
    redis.set("scan_job:#{job_id}", "failed:#{e.message}")
    raise
  end
end
