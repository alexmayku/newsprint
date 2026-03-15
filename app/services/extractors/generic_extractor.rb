require "nokogiri"

module Extractors
  class GenericExtractor < BaseExtractor
    BOILERPLATE_TAGS = %w[nav footer header].freeze

    def extract
      doc = Nokogiri::HTML(html)

      title = extract_title(doc)
      author = extract_author(doc)
      body_node = find_content_block(doc)

      cleaned_html = HtmlSanitiser.sanitise(body_node.inner_html)
      cleaned_doc = Nokogiri::HTML.fragment(cleaned_html)

      [
        {
          title: title,
          author: author,
          body_html: cleaned_html,
          image_urls: cleaned_doc.css("img").filter_map { |img| img["src"] },
          link_urls: cleaned_doc.css("a").filter_map { |a| a["href"] }
        }
      ]
    end

    private

    def extract_title(doc)
      h1 = doc.at_css("h1")
      return h1.text.strip if h1

      h2 = doc.at_css("h2")
      return h2.text.strip if h2

      metadata[:subject]
    end

    def extract_author(doc)
      byline = doc.at_css(".byline, .author, [class*='byline'], [class*='author']")
      if byline
        text = byline.text.strip.sub(/\ABy\s+/i, "")
        return text unless text.empty?
      end

      metadata[:sender_name]
    end

    def find_content_block(doc)
      # Prefer semantic content containers first
      semantic = doc.at_css("article, main, [role='main']")
      return semantic if semantic

      # Score non-boilerplate block elements by text length
      candidates = doc.css("div, section, td").reject do |el|
        BOILERPLATE_TAGS.include?(el.name) || boilerplate_ancestor?(el)
      end

      best = candidates.max_by { |el| el.text.strip.length }
      best || doc.at_css("body") || doc
    end

    def boilerplate_ancestor?(el)
      el.ancestors.any? { |a| BOILERPLATE_TAGS.include?(a.name) }
    end
  end
end
