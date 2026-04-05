class CropImageJob < ApplicationJob
  queue_as :default

  def perform(task_id, upload_id:, crop_x:, crop_y:, crop_width:, crop_height:)
    task   = Task.find_by!(task_id: task_id)
    upload = task.uploads.completed.find_by!(upload_id: upload_id)

    crop_upload(upload, x: crop_x, y: crop_y, width: crop_width, height: crop_height)
    task.update!(status: "done")
  rescue => e
    Task.find_by(task_id: task_id)&.update!(status: "failed")
    raise e
  end

  private

  def crop_upload(upload, x:, y:, width:, height:)
    ext = upload.normalized_extension

    result = upload.file.open do |source|
      ImageProcessing::Vips
        .source(source)
        .custom do |img|
          img_w = img.width
          img_h = img.height
          x = x.clamp(0, img_w - 1)
          y = y.clamp(0, img_h - 1)
          width  = width.clamp(1, img_w - x)
          height = height.clamp(1, img_h - y)
          img.crop(x, y, width, height)
        end
        .convert(ext)
        .call
    end

    upload.compressed_file.attach(
      io: result,
      filename: upload.filename,
      content_type: upload.file.content_type
    )
  end
end
