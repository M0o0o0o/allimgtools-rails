class RotateImagesJob < ApplicationJob
  queue_as :default

  def perform(task_id, upload_id:, rotate:)
    task = Task.find_by!(task_id: task_id)
    upload = task.uploads.completed.find_by!(upload_id: upload_id)

    rotate_upload(upload, rotate: rotate.to_i)
    task.update!(status: "done")
  rescue => e
    Task.find_by(task_id: task_id)&.update!(status: "failed")
    raise e
  end

  private

  def rotate_upload(upload, rotate:)
    ext = upload.normalized_extension

    result = upload.file.open do |source|
      pipeline = ImageProcessing::Vips.source(source)

      pipeline = case rotate
      when 90  then pipeline.custom { |img| img.rot(:d90) }
      when 180 then pipeline.custom { |img| img.rot(:d180) }
      when 270 then pipeline.custom { |img| img.rot(:d270) }
      else pipeline
      end

      pipeline.convert(ext).call
    end

    upload.compressed_file.attach(
      io: result,
      filename: upload.filename,
      content_type: upload.file.content_type
    )
  end
end
