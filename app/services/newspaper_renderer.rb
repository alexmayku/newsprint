class NewspaperRenderer
  TEMPLATE_PATH = Rails.root.join("app/views/newspapers/_print_template.html.erb")

  def initialize(newspaper)
    @newspaper = newspaper
    @articles = newspaper.all_articles.includes(:qr_references).order(:position)
  end

  def to_html
    template = ERB.new(File.read(TEMPLATE_PATH))
    newspaper = @newspaper
    articles = @articles
    date = Date.current.strftime("%B %-d, %Y")
    edition = newspaper.edition_number

    template.result(binding)
  end
end
