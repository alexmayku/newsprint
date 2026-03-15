require "rqrcode"

class QrCodeGenerator
  def self.generate_svg(url)
    qr = RQRCode::QRCode.new(url)
    qr.as_svg(module_size: 4, standalone: true, use_path: true)
  end

  def self.generate_for_article(article, offset: 0)
    article.link_urls.each_with_index.map do |url, index|
      article.qr_references.create!(
        url: url,
        reference_number: offset + index + 1,
        label: label_from_url(url),
        qr_svg: generate_svg(url)
      )
    end
  end

  def self.label_from_url(url)
    uri = URI.parse(url)
    path = uri.path.to_s.chomp("/")

    if path.empty? || path == ""
      uri.host
    else
      path.split("/").last
    end
  rescue URI::InvalidURIError
    url.split("/").last || "link"
  end
end
