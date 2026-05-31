class CompressImagesJob < ApplicationJob
  queue_as :default

  def perform(task_id, quality:, upload_ids: nil, strip_exif: false)
    task = Task.find_by!(task_id: task_id)
    uploads = task.uploads.completed
    uploads = uploads.where(upload_id: upload_ids) if upload_ids.present?

    uploads.find_each do |upload|
      compress_upload(upload, quality: quality, strip_exif: strip_exif)
    rescue => e
      Rails.logger.error "CompressImagesJob: #{upload.upload_id} failed: #{e.message}"
    end

    task.update!(status: "done")
  rescue => e
    Task.find_by(task_id: task_id)&.update!(status: "failed")
    raise e
  end

  private

  def compress_upload(upload, quality:, strip_exif: false)
    ext = upload.normalized_extension
    keep_opts = strip_exif ? { keep: :none } : {}

    result = upload.file.open do |source|
      pipeline = ImageProcessing::Vips.source(source)
      pipeline = case ext
      when "jpeg" then pipeline.convert("jpeg").saver(quality: quality, **keep_opts)
      when "webp"  then pipeline.convert("webp").saver(quality: quality, **keep_opts)
      when "png"
        palette = quality < 100
        pipeline.convert("png").saver(compression: 9, palette: palette, Q: quality, **keep_opts)
      when "avif"  then pipeline.convert("avif").saver(quality: quality, **keep_opts)
      when "gif"
        colours = (quality / 100.0 * 254 + 2).round.clamp(2, 256)
        bitdepth = Math.log2(colours).ceil.clamp(1, 8)
        pipeline.convert("gif").saver(bitdepth: bitdepth, dither: 1.0, effort: 7, **keep_opts)
      else pipeline.saver(quality: quality, **keep_opts)
      end
      pipeline.call
    end

    if result.size < upload.file.byte_size
      upload.compressed_file.attach(
        io: result,
        filename: upload.filename,
        content_type: upload.file.content_type
      )
    else
      upload.compressed_file.attach(upload.file.blob)
    end
  end
end
