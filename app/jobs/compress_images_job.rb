class CompressImagesJob < ApplicationJob
  queue_as :default

  def perform(task_id, quality:, upload_ids: nil)
    task = Task.find_by!(task_id: task_id)
    uploads = task.uploads.completed
    uploads = uploads.where(upload_id: upload_ids) if upload_ids.present?

    uploads.find_each do |upload|
      compress_upload(upload, quality: quality)
    end

    task.update!(status: "done")
  rescue => e
    Task.find_by(task_id: task_id)&.update!(status: "failed")
    raise e
  end

  private

  def compress_upload(upload, quality:)
    ext = upload.normalized_extension

    result = upload.file.open do |source|
      pipeline = ImageProcessing::Vips.source(source)
      pipeline = case ext
      when "jpeg" then pipeline.convert("jpeg").saver(quality: quality, strip: true)
      when "webp"  then pipeline.convert("webp").saver(quality: quality, strip: true)
      when "png"   then pipeline.convert("png").saver(compression: 9)
      else              pipeline.saver(quality: quality, strip: true)
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
