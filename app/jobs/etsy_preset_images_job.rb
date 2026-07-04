class EtsyPresetImagesJob < ApplicationJob
  queue_as :default

  MAX_DIMENSION = 2000

  EXTENSION_MAP    = { "jpeg" => "jpg", "png" => "png" }.freeze
  CONTENT_TYPE_MAP = { "jpeg" => "image/jpeg", "png" => "image/png" }.freeze

  def perform(task_id, to_format:, quality:, strip_exif:, upload_ids: nil)
    task = Task.find_by!(task_id: task_id)
    uploads = task.uploads.completed
    uploads = uploads.where(upload_id: upload_ids) if upload_ids.present?

    uploads.find_each do |upload|
      process_upload(upload, to_format: to_format, quality: quality, strip_exif: strip_exif)
    rescue => e
      Rails.logger.error "EtsyPresetImagesJob: #{upload.upload_id} failed: #{e.message}"
    end

    task.update!(status: "done")
  rescue => e
    Task.find_by(task_id: task_id)&.update!(status: "failed")
    raise e
  end

  private

  # Resizes to Etsy's recommended bound, forces sRGB (fixes CMYK exports),
  # converts to an Etsy-supported format, and compresses — in one pass.
  def process_upload(upload, to_format:, quality:, strip_exif:)
    keep_opts = strip_exif ? { keep: :none } : {}

    result = upload.file.open do |source|
      has_alpha = Vips::Image.new_from_file(source.path).has_alpha?

      pipeline = ImageProcessing::Vips.source(source)
      pipeline = pipeline.resize_to_limit(MAX_DIMENSION, MAX_DIMENSION)
      pipeline = pipeline.colourspace("srgb")
      # Etsy renders transparent PNG areas as black, so always flatten to white —
      # regardless of output format.
      pipeline = pipeline.flatten(background: [ 255, 255, 255 ]) if has_alpha
      pipeline.convert(to_format).saver(quality: quality, **keep_opts).call
    end

    ext          = EXTENSION_MAP.fetch(to_format, to_format)
    new_filename = "#{File.basename(upload.filename, '.*')}.#{ext}"
    content_type = CONTENT_TYPE_MAP.fetch(to_format, upload.file.content_type)

    upload.compressed_file.attach(io: result, filename: new_filename, content_type: content_type)
  end
end
