require "nokogiri"

module Extractors
  class MailchimpExtractor < BaseExtractor
    def extract
      doc = Nokogiri::HTML(html)

      content_blocks = doc.css(".mcnTextContent")
      blocks_with_headings = content_blocks.select { |block| block.at_css("h2, h3") }

      if blocks_with_headings.size > 1
        blocks_with_headings.map { |block| extract_article(block) }
      elsif content_blocks.any?
        [ extract_article(content_blocks.first, fallback_title: true) ]
      else
        [ extract_full_body(doc) ]
      end
    end

    private

    def extract_article(block, fallback_title: false)
      title_el = block.at_css("h2, h3")
      title = title_el&.text&.strip
      title_el&.remove

      title = metadata[:subject] if fallback_title && title.nil?

      cleaned_html = HtmlSanitiser.sanitise(block.inner_html)
      cleaned_doc = Nokogiri::HTML.fragment(cleaned_html)

      {
        title: title,
        author: metadata[:sender_name],
        body_html: cleaned_html,
        image_urls: cleaned_doc.css("img").filter_map { |img| img["src"] },
        link_urls: cleaned_doc.css("a").filter_map { |a| a["href"] }
      }
    end

    def extract_full_body(doc)
      body = doc.at_css("body") || doc
      cleaned_html = HtmlSanitiser.sanitise(body.inner_html)
      cleaned_doc = Nokogiri::HTML.fragment(cleaned_html)

      {
        title: metadata[:subject],
        author: metadata[:sender_name],
        body_html: cleaned_html,
        image_urls: cleaned_doc.css("img").filter_map { |img| img["src"] },
        link_urls: cleaned_doc.css("a").filter_map { |a| a["href"] }
      }
    end
  end
end
