require "grover"
require "pdf-reader"

class PdfGenerator
  class RenderError < StandardError; end

  DEFAULT_OPTIONS = {
    print_background: true,
    prefer_css_page_size: true,
    margin: { top: "0", bottom: "0", left: "0", right: "0" },
    display_url: "http://localhost",
    wait_until: "networkidle0"
  }.freeze

  attr_reader :options

  def initialize(html, **overrides)
    @html = html
    @options = DEFAULT_OPTIONS.merge(overrides)
  end

  def to_pdf
    Grover.new(@html, **@options).to_pdf
  rescue Grover::Error => e
    raise RenderError, e.message
  end

  def to_pdf_with_metadata
    pdf_data = to_pdf
    reader = PDF::Reader.new(StringIO.new(pdf_data))
    { pdf_data: pdf_data, page_count: reader.page_count }
  end
end
