class PageEstimator
  CHARS_PER_PAGE = 3000
  IMAGE_PAGE_FRACTION = 0.3
  QR_PER_PAGE = 6

  def self.estimate(newsletter)
    articles = newsletter.articles

    return 1 if articles.empty?

    total_article_pages = 0
    total_links = 0

    articles.each do |article|
      text_length = ActionController::Base.helpers.strip_tags(article.body_html).length
      text_pages = (text_length.to_f / CHARS_PER_PAGE).ceil
      image_pages = article.image_urls.size * IMAGE_PAGE_FRACTION
      article_pages = [ (text_pages + image_pages).ceil, 1 ].max
      total_article_pages += article_pages
      total_links += article.link_urls.size
    end

    front_page = 1
    appendix_pages = total_links > 0 ? (total_links.to_f / QR_PER_PAGE).ceil : 0

    [ front_page + total_article_pages + appendix_pages, 1 ].max
  end

  def self.estimate_batch(newsletters)
    newsletters.each_with_object({}) do |newsletter, hash|
      hash[newsletter.id] = estimate(newsletter)
    end
  end
end
