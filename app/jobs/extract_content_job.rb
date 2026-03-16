class ExtractContentJob < ApplicationJob
  queue_as :default

  def perform(newsletter_id, job_id, gmail_client: nil, redis: nil)
    newsletter = Newsletter.find(newsletter_id)
    user = newsletter.user
    redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))

    redis.set("extract_job:#{job_id}", "extracting")

    client = gmail_client || GmailClient.new(user)

    message_ids = client.fetch_messages(query: "from:#{newsletter.sender_email} newer_than:30d", max_results: 1)
    return redis.set("extract_job:#{job_id}", "complete:0") if message_ids.empty?

    detail = client.fetch_message_detail(message_ids.first[:id])

    metadata = {
      sender_email: detail[:from_email],
      sender_name: detail[:from_name],
      subject: detail[:subject],
      date: detail[:date]
    }

    extracted_articles = ExtractorRegistry.extract(detail[:html_body], metadata)

    ActiveRecord::Base.transaction do
      newsletter.articles.destroy_all

      qr_offset = 0
      extracted_articles.each_with_index do |article_data, index|
        article = newsletter.articles.create!(
          title: article_data[:title].presence || metadata[:subject].presence || "Untitled",
          author: article_data[:author],
          body_html: article_data[:body_html].presence || "<p></p>",
          position: index,
          image_urls: article_data[:image_urls] || [],
          link_urls: article_data[:link_urls] || []
        )

        QrCodeGenerator.generate_for_article(article, offset: qr_offset)
        qr_offset += article.link_urls.size

        ImageDownloader.download_for_article(article)
      end
    end

    redis.set("extract_job:#{job_id}", "complete:#{extracted_articles.size}")
  rescue GmailClient::ApiError => e
    redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
    redis.set("extract_job:#{job_id}", "failed:#{e.message}")
    raise
  end
end
