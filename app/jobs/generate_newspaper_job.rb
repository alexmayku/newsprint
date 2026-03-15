class GenerateNewspaperJob < ApplicationJob
  queue_as :default

  def perform(newspaper_id, job_id, gmail_client: nil, pdf_generator: nil, pdf_postprocessor: nil, redis: nil)
    newspaper = Newspaper.find(newspaper_id)
    redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))

    redis.set("generate_job:#{job_id}", "generating")
    newspaper.generating!

    # Extract content for each newsletter
    redis.set("generate_job:#{job_id}", "extracting")
    newspaper.newsletters.each do |newsletter|
      client = gmail_client || GmailClient.new(newspaper.user)
      ExtractContentJob.new.perform(newsletter.id, "#{job_id}_extract_#{newsletter.id}", gmail_client: client)
    end
    newspaper.reload

    # Render HTML
    redis.set("generate_job:#{job_id}", "rendering")
    html = NewspaperRenderer.new(newspaper).to_html

    # Generate PDF
    redis.set("generate_job:#{job_id}", "processing")
    generator = pdf_generator || default_pdf_generator
    result = generator.call(html)
    pdf_data = result[:pdf_data]
    page_count = result[:page_count]

    # Post-process
    processor = pdf_postprocessor || default_pdf_postprocessor
    final_pdf = processor.call(pdf_data)

    # Attach and update
    newspaper.pdf.attach(
      io: StringIO.new(final_pdf),
      filename: "newsprint-edition-#{newspaper.edition_number}.pdf",
      content_type: "application/pdf"
    )
    newspaper.update!(page_count: page_count, status: :generated, generated_at: Time.current)

    redis.set("generate_job:#{job_id}", "complete:#{page_count}")
  rescue => e
    newspaper = Newspaper.find_by(id: newspaper_id)
    newspaper&.failed!
    redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
    redis.set("generate_job:#{job_id}", "failed:#{e.message}")
    raise
  end

  private

  def default_pdf_generator
    ->(html) { PdfGenerator.new(html).to_pdf_with_metadata }
  end

  def default_pdf_postprocessor
    ->(pdf_data) { PdfPostprocessor.process(pdf_data) }
  end
end
