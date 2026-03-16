require "rqrcode"

class QrCodeGenerator
  def self.generate_svg(url)
    qr = RQRCode::QRCode.new(url)
    qr.as_svg(module_size: 4, standalone: true, use_path: true)
  rescue RQRCodeCore::QRCodeRunTimeError
    nil
  end

  def self.generate_for_article(article, offset: 0)
    ref_number = offset
    article.link_urls.filter_map do |url|
      svg = generate_svg(url)
      next unless svg

      ref_number += 1
      article.qr_references.create!(
        url: url,
        reference_number: ref_number,
        label: label_from_url(url),
        qr_svg: svg
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
