require "tempfile"

class PdfPostprocessor
  class GhostscriptError < StandardError; end

  def self.process(pdf_data)
    result = to_cmyk(pdf_data)
    add_crop_marks(result)
  end

  def self.to_cmyk(pdf_data)
    run_gs(pdf_data,
      "-dSAFER",
      "-dBATCH",
      "-dNOPAUSE",
      "-sDEVICE=pdfwrite",
      "-sColorConversionStrategy=CMYK",
      "-dProcessColorModel=/DeviceCMYK"
    )
  end

  def self.add_crop_marks(pdf_data)
    run_gs(pdf_data,
      "-dSAFER",
      "-dBATCH",
      "-dNOPAUSE",
      "-sDEVICE=pdfwrite",
      "-dUseCropBox"
    )
  end

  class << self
    private

    def run_gs(pdf_data, *args)
      input = Tempfile.new([ "input", ".pdf" ])
      output = Tempfile.new([ "output", ".pdf" ])

      begin
        input.binmode
        input.write(pdf_data)
        input.close

        output.close

        success = system("gs", *args, "-sOutputFile=#{output.path}", input.path,
                         out: File::NULL, err: File::NULL)

        raise GhostscriptError, "Ghostscript failed or not found" unless success

        File.binread(output.path)
      ensure
        input.unlink
        output.unlink
      end
    end
  end
end
