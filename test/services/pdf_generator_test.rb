require "test_helper"

class PdfGeneratorTest < ActiveSupport::TestCase
  setup do
    @simple_html = <<~HTML
      <!DOCTYPE html>
      <html><head><title>Test</title></head>
      <body><h1>Hello World</h1><p>Test content</p></body></html>
    HTML

    @two_page_html = <<~HTML
      <!DOCTYPE html>
      <html><head><title>Two Pages</title>
      <style>
        @page { size: A4; margin: 10mm; }
        .page-break { break-before: page; }
      </style>
      </head>
      <body>
        <div><h1>Page One</h1><p>Content on page one</p></div>
        <div class="page-break"><h1>Page Two</h1><p>Content on page two</p></div>
      </body></html>
    HTML
  end

  test "to_pdf returns binary data starting with %PDF" do
    pdf = PdfGenerator.new(@simple_html).to_pdf
    assert pdf.start_with?("%PDF")
  end

  test "passes prefer_css_page_size true to Grover" do
    generator = PdfGenerator.new(@simple_html)
    assert_equal true, generator.options[:prefer_css_page_size]
  end

  test "passes print_background true" do
    generator = PdfGenerator.new(@simple_html)
    assert_equal true, generator.options[:print_background]
  end

  test "to_pdf_with_metadata returns pdf_data and page_count" do
    result = PdfGenerator.new(@two_page_html).to_pdf_with_metadata
    assert result[:pdf_data].start_with?("%PDF")
    assert_kind_of Integer, result[:page_count]
    assert_equal 2, result[:page_count]
  end

  test "invalid HTML still produces a PDF" do
    pdf = PdfGenerator.new("<not>valid<html>").to_pdf
    assert pdf.start_with?("%PDF")
  end

  test "Grover error is wrapped in PdfGenerator::RenderError" do
    generator = PdfGenerator.new(@simple_html)
    # Override to_pdf to simulate a Grover error
    generator.define_singleton_method(:to_pdf) do
      raise Grover::Error, "Chrome crashed"
    rescue Grover::Error => e
      raise PdfGenerator::RenderError, e.message
    end

    assert_raises(PdfGenerator::RenderError) do
      generator.to_pdf
    end
  end
end
