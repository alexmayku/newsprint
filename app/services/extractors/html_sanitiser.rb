require "nokogiri"

module Extractors
  module HtmlSanitiser
    TRACKING_PIXEL_SRC_PATTERNS = /track|pixel|open|beacon|wf_open/i
    SOCIAL_DOMAINS = %w[twitter.com facebook.com instagram.com linkedin.com youtube.com x.com].freeze
    VIEW_IN_BROWSER_PATTERN = /view\s+(this\s+)?(email\s+)?(in\s+)?(your\s+)?browser/i
    UNSUBSCRIBE_PATTERN = /unsubscribe/i

    def self.sanitise(html)
      doc = Nokogiri::HTML.fragment(html)

      remove_scripts_and_styles(doc)
      remove_tracking_pixels(doc)
      remove_unsubscribe_blocks(doc)
      remove_view_in_browser(doc)
      remove_social_footer_links(doc)
      remove_empty_elements(doc)

      doc.to_html
    end

    class << self
      private

      def remove_scripts_and_styles(doc)
        doc.css("script, style").each(&:remove)
      end

      def remove_tracking_pixels(doc)
        doc.css("img").each do |img|
          width = img["width"].to_s.strip
          height = img["height"].to_s.strip
          src = img["src"].to_s

          is_tiny = (width == "1" || height == "1")
          is_tracking = TRACKING_PIXEL_SRC_PATTERNS.match?(src)

          img.remove if is_tiny || is_tracking
        end
      end

      def remove_unsubscribe_blocks(doc)
        doc.css("a").each do |link|
          href = link["href"].to_s
          text = link.text

          if UNSUBSCRIBE_PATTERN.match?(href) || UNSUBSCRIBE_PATTERN.match?(text)
            parent = link.parent
            if parent && %w[p div td].include?(parent.name)
              parent.remove
            else
              link.remove
            end
          end
        end
      end

      def remove_view_in_browser(doc)
        doc.css("a").each do |link|
          if VIEW_IN_BROWSER_PATTERN.match?(link.text)
            parent = link.parent
            if parent && %w[p div td].include?(parent.name)
              parent.remove
            else
              link.remove
            end
          end
        end
      end

      def remove_social_footer_links(doc)
        doc.css("a").each do |link|
          href = link["href"].to_s
          if SOCIAL_DOMAINS.any? { |domain| href.include?(domain) }
            parent = link.parent
            if parent && %w[p div td].include?(parent.name) && parent.css("a").all? { |a| SOCIAL_DOMAINS.any? { |d| a["href"].to_s.include?(d) } }
              parent.remove
            else
              link.remove
            end
          end
        end
      end

      def remove_empty_elements(doc)
        doc.css("p, div").each do |el|
          el.remove if el.text.strip.empty? && el.css("img, video, iframe").empty?
        end
      end
    end
  end
end
