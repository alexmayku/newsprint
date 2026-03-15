class NewspapersController < ApplicationController
  def create
    newsletter_ids = Array(params[:newsletter_ids]).map(&:to_i).reject(&:zero?)

    if newsletter_ids.empty?
      render json: { error: "At least one newsletter must be selected" }, status: :unprocessable_entity
      return
    end

    newspaper = current_user.newspapers.create!
    newspaper.newsletter_ids = newsletter_ids

    GenerateNewspaperJob.perform_later(newspaper.id, "newspaper_#{newspaper.id}")

    redirect_to preview_newspaper_path(newspaper)
  end

  def status
    newspaper = current_user.newspapers.find_by(id: params[:id])
    return head :not_found unless newspaper

    redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
    status = redis.get("generate_job:newspaper_#{newspaper.id}") || newspaper.status
    render json: { status: status }
  end

  def preview
    newspaper = current_user.newspapers.find_by(id: params[:id])
    return head :not_found unless newspaper

    render inertia: "Newspapers/Preview", props: {
      newspaper: {
        id: newspaper.id,
        title: newspaper.title,
        edition_number: newspaper.edition_number,
        page_count: newspaper.page_count,
        status: newspaper.status,
        pdf_url: newspaper.pdf.attached? ? pdf_newspaper_path(newspaper) : nil,
        generated_at: newspaper.generated_at&.iso8601,
        newsletters: newspaper.newsletters.map { |n|
          { id: n.id, title: n.title, sender_email: n.sender_email }
        }
      }
    }
  end

  def pdf
    newspaper = current_user.newspapers.find_by(id: params[:id])
    return head :not_found unless newspaper
    return head :not_found unless newspaper.pdf.attached?

    redirect_to newspaper.pdf, allow_other_host: true
  end
end
