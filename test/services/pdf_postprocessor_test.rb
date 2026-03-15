require "test_helper"

class PdfPostprocessorTest < ActiveSupport::TestCase
  setup do
    html = "<!DOCTYPE html><html><body><h1 style='color:red'>Test</h1></body></html>"
    @pdf_data = PdfGenerator.new(html).to_pdf
  end

  test ".to_cmyk returns binary data starting with %PDF" do
    result = PdfPostprocessor.to_cmyk(@pdf_data)
    assert result.start_with?("%PDF")
  end

  test "output is different from input after CMYK conversion" do
    result = PdfPostprocessor.to_cmyk(@pdf_data)
    assert_not_equal @pdf_data, result
  end

  test ".add_crop_marks returns a valid PDF" do
    result = PdfPostprocessor.add_crop_marks(@pdf_data)
    assert result.start_with?("%PDF")
  end

  test ".process chains both operations and returns a valid PDF" do
    result = PdfPostprocessor.process(@pdf_data)
    assert result.start_with?("%PDF")
  end

  test "raises GhostscriptError if Ghostscript is not available" do
    original_path = ENV["PATH"]
    ENV["PATH"] = ""
    assert_raises(PdfPostprocessor::GhostscriptError) do
      PdfPostprocessor.to_cmyk(@pdf_data)
    end
  ensure
    ENV["PATH"] = original_path
  end
end
