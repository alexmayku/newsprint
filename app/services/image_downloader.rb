require "net/http"

class ImageDownloader
  MINIMUM_PRINT_DPI = 150

  def self.download_for_article(article)
    seen = Set.new

    article.image_urls.each do |url|
      next if seen.include?(url)
      seen.add(url)

      download_and_attach(article, url)
    end
  end

  def self.image_meets_print_dpi?(blob, target_width_mm: 130)
    width_px = image_width(blob)
    return false unless width_px

    target_width_inches = target_width_mm / 25.4
    dpi = width_px / target_width_inches
    dpi >= MINIMUM_PRINT_DPI
  end

  class << self
    private

    def download_and_attach(article, url)
      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.warn("ImageDownloader: Failed to download #{url} (#{response.code})")
        return
      end

      filename = File.basename(uri.path).presence || "image"
      content_type = response["Content-Type"] || "image/png"

      article.images.attach(
        io: StringIO.new(response.body),
        filename: filename,
        content_type: content_type
      )
    rescue StandardError => e
      Rails.logger.warn("ImageDownloader: Error downloading #{url}: #{e.message}")
    end

    def image_width(blob)
      # Try ActiveStorage metadata first
      blob.analyze unless blob.analyzed?
      width = blob.metadata[:width] || blob.metadata["width"]
      return width if width

      # Fall back to parsing PNG header directly
      blob.open do |file|
        data = file.read(30)
        if data[0..7] == "\x89PNG\r\n\x1a\n".b
          return data[16..19].unpack1("N")
        end
      end

      nil
    end
  end
end
