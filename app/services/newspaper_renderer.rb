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

  def prepare_body_for_print(body_html, qr_references)
    doc = Nokogiri::HTML.fragment(body_html)

    qr_by_url = qr_references.index_by(&:url)

    doc.css("a").each do |link|
      href = link["href"]
      qr = qr_by_url[href]

      if qr
        sup = Nokogiri::XML::Node.new("sup", doc)
        sup["class"] = "qr-ref"
        sup.content = "[#{qr.reference_number}]"
        link.add_next_sibling(sup)
      end

      link.replace(link.children)
    end

    doc.to_html
  end
end
