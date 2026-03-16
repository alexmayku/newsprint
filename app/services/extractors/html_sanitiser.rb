require "nokogiri"

module Extractors
  module HtmlSanitiser
    TRACKING_PIXEL_SRC_PATTERNS = /track|pixel|open|beacon|wf_open/i
    SOCIAL_DOMAINS = %w[twitter.com facebook.com instagram.com linkedin.com youtube.com x.com].freeze
    VIEW_IN_BROWSER_PATTERN = /view\s+(this\s+)?(email\s+)?(in\s+)?(your\s+)?browser/i
    UNSUBSCRIBE_PATTERN = /unsubscribe/i
    CTA_PATTERN = /\A\s*(read\s+more|read\s+in\s+app|subscribe(\s+here)?|share(\s+this)?|view\s+online|click\s+here|get\s+started|learn\s+more|sign\s+up|download|shop\s+now|upgrade(\s+to\s+paid)?|start\s+writing)\s*[→›»]?\s*\z/i
    FORWARDED_EMAIL_PATTERN = /\AForwarded this email\b/i
    INVISIBLE_CHARS = /[\u034F\u00AD\u200B\u200C\u200D\uFEFF\u2060]/
    PLATFORM_ICON_PATHS = %w[substackcdn.com/icon/ substackcdn.com/img/email/].freeze

    def self.sanitise(html)
      doc = Nokogiri::HTML.fragment(html)

      # Remove elements (most specific first)
      remove_scripts_and_styles(doc)
      remove_tracking_pixels(doc)
      remove_platform_chrome(doc)
      remove_platform_engagement(doc)
      remove_unsubscribe_blocks(doc)
      remove_view_in_browser(doc)
      remove_forwarded_email_banners(doc)
      remove_social_footer_links(doc)
      remove_cta_buttons(doc)
      remove_subscription_pitch_blocks(doc)
      remove_horizontal_rules(doc)
      remove_preheader_text(doc)

      # Strip attributes
      strip_inline_styles(doc)
      strip_class_attributes(doc)
      strip_data_attributes(doc)

      # Final cleanup
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

      # Remove platform-specific chrome (post headers, paywalls)
      def remove_platform_chrome(doc)
        doc.css('[aria-label="Post header"], [data-testid="paywall"], [data-component-name="Paywall"]').each(&:remove)
      end

      # Remove platform engagement links and UI icon images
      def remove_platform_engagement(doc)
        doc.css("a").each do |link|
          href = link["href"].to_s
          link.remove if href.include?("substack.com/app-link")
        end

        doc.css("img").each do |img|
          src = img["src"].to_s
          if PLATFORM_ICON_PATHS.any? { |path| src.include?(path) }
            parent = img.parent
            if parent&.name == "a"
              parent.remove
            else
              img.remove
            end
          end
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

      def remove_forwarded_email_banners(doc)
        doc.css("span, div, p, td").each do |el|
          text = el.text.strip
          next unless text.match?(FORWARDED_EMAIL_PATTERN)
          # Only remove leaf-like elements, not parent containers that hold article content
          next unless el.css("p, h1, h2, h3, h4, h5, h6, figure, blockquote, ul, ol").empty?
          el.remove
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

      def remove_cta_buttons(doc)
        doc.css("a").each do |link|
          if CTA_PATTERN.match?(link.text)
            parent = link.parent
            if parent && %w[p div td].include?(parent.name) && parent.css("a").size == 1
              parent.remove
            else
              link.remove
            end
          end
        end
      end

      # Remove "A subscription gets you:" and similar pitch sections
      def remove_subscription_pitch_blocks(doc)
        doc.css("h2, h3").each do |heading|
          text = heading.text.strip
          if text.match?(/\Aa\s+subscription\s+gets\s+you/i)
            parent = heading.parent
            if parent && %w[div section].include?(parent.name)
              parent.remove
            else
              heading.remove
            end
          end
        end
      end

      def remove_horizontal_rules(doc)
        doc.css("hr").each(&:remove)
      end

      # Remove divs containing only invisible Unicode characters (email preheader text)
      def remove_preheader_text(doc)
        doc.css("div, span").each do |el|
          next unless el.css("img, video, iframe, svg, figure, p, h1, h2, h3, h4, h5, h6, blockquote, ul, ol").empty?
          cleaned = el.text.gsub(INVISIBLE_CHARS, "").strip
          el.remove if cleaned.empty?
        end
      end

      def strip_inline_styles(doc)
        doc.css("[style]").each { |el| el.remove_attribute("style") }
      end

      def strip_class_attributes(doc)
        doc.css("[class]").each { |el| el.remove_attribute("class") }
      end

      def strip_data_attributes(doc)
        doc.css("*").each do |el|
          el.attribute_nodes.each do |attr|
            attr.remove if attr.name.start_with?("data-")
          end
        end
      end

      # Expanded to handle table elements left empty after removing platform chrome
      def remove_empty_elements(doc)
        %w[span td tr tbody table p div].each do |tag|
          doc.css(tag).each do |el|
            el.remove if el.text.strip.empty? && el.css("img, video, iframe, svg, figure").empty?
          end
        end
      end
    end
  end
end
