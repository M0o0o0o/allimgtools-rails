class StripExifJob < ApplicationJob
  queue_as :default

  CONTENT_TYPE_MAP = { "jpeg" => "image/jpeg", "png" => "image/png", "webp" => "image/webp", "gif" => "image/gif" }.freeze

  def perform(task_id, upload_ids: nil)
    task = Task.find_by!(task_id: task_id)
    uploads = task.uploads.completed
    uploads = uploads.where(upload_id: upload_ids) if upload_ids.present?

    uploads.find_each do |upload|
      strip_exif(upload)
    end

    task.update!(status: "done")
  rescue => e
    Task.find_by(task_id: task_id)&.update!(status: "failed")
    raise e
  end

  private

  def strip_exif(upload)
    ext = upload.normalized_extension

    result = upload.file.open do |source|
      pipeline = ImageProcessing::Vips.source(source)
      pipeline = case ext
      when "jpeg" then pipeline.convert("jpeg").saver(strip: true)
      when "webp"  then pipeline.convert("webp").saver(strip: true)
      when "png"   then pipeline.convert("png").saver(strip: true)
      else              pipeline.saver(strip: true)
      end
      pipeline.call
    end

    upload.compressed_file.attach(
      io: result,
      filename: upload.filename,
      content_type: CONTENT_TYPE_MAP.fetch(ext, upload.file.content_type)
    )
  end
end
