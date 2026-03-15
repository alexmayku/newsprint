module Extractors
  class BaseExtractor
    REQUIRED_METADATA_KEYS = %i[sender_email sender_name subject date].freeze

    attr_reader :html, :metadata

    # Subclasses must implement #extract, returning:
    # Array of Hashes, each with { title:, author:, body_html:, image_urls:, link_urls: }
    def initialize(html, metadata)
      validate_metadata!(metadata)
      @html = html
      @metadata = metadata
    end

    def extract
      raise NotImplementedError, "#{self.class}#extract must be implemented"
    end

    private

    def validate_metadata!(metadata)
      missing = REQUIRED_METADATA_KEYS - metadata.keys
      raise ArgumentError, "Missing required metadata keys: #{missing.join(', ')}" if missing.any?
    end
  end
end
