class ImageProcessor
  MAX_DIMENSION = 1920
  QUALITY = 80

  def self.process(file)
    return file unless processable?(file)

    processed = ImageProcessing::Vips
      .source(file.tempfile)
      .resize_to_limit(MAX_DIMENSION, MAX_DIMENSION)
      .convert("webp")
      .saver(strip: true, quality: QUALITY)
      .call

    ActionDispatch::Http::UploadedFile.new(
      tempfile: processed,
      filename: normalize_filename(file.original_filename),
      type: "image/webp"
    )
  end

  def self.processable?(file)
    file.respond_to?(:content_type) && file.content_type&.start_with?("image/")
  end

  def self.normalize_filename(original)
    base = File.basename(original, ".*")
    slug = base
      .unicode_normalize(:nfkd)
      .encode("ASCII", invalid: :replace, undef: :replace, replace: "")
      .downcase
      .gsub(/[^a-z0-9]+/, "-")
      .gsub(/\A-+|-+\z/, "")
    slug = "image" if slug.empty?
    "#{slug}.webp"
  end
end
