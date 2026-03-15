require "nokogiri"

module Extractors
  class SubstackExtractor < BaseExtractor
    def extract
      doc = Nokogiri::HTML(html)

      title = extract_title(doc)
      author = extract_author(doc)
      body_node = extract_body(doc)

      cleaned_html = HtmlSanitiser.sanitise(body_node&.inner_html || "")
      cleaned_doc = Nokogiri::HTML.fragment(cleaned_html)

      image_urls = cleaned_doc.css("img").filter_map { |img| img["src"] }
      link_urls = cleaned_doc.css("a").filter_map { |a| a["href"] }

      [
        {
          title: title,
          author: author,
          body_html: cleaned_html,
          image_urls: image_urls,
          link_urls: link_urls
        }
      ]
    end

    private

    def extract_title(doc)
      h1 = doc.at_css("h1")
      h1&.text&.strip
    end

    def extract_author(doc)
      byline = doc.at_css(".byline, .author, .post-meta .byline")
      return byline.text.strip.sub(/\ABy\s+/i, "") if byline

      metadata[:sender_name]
    end

    def extract_body(doc)
      doc.at_css(".body, .post-body, .body.markup, .email-body")
    end
  end
end
