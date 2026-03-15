class ExtractorRegistry
  PLATFORM_MAP = {
    "substack.com" => Extractors::SubstackExtractor,
    "mailchimp.com" => Extractors::MailchimpExtractor
  }

  def self.extractor_for(metadata)
    domain = metadata[:sender_email].split("@").last.downcase
    PLATFORM_MAP.each do |pattern, klass|
      return klass if domain == pattern || domain.end_with?(".#{pattern}")
    end
    Extractors::GenericExtractor
  end

  def self.extract(html, metadata)
    klass = extractor_for(metadata)
    klass.new(html, metadata).extract
  end

  def self.register(pattern, klass)
    PLATFORM_MAP[pattern] = klass
  end

  def self.deregister(pattern)
    PLATFORM_MAP.delete(pattern)
  end
end
