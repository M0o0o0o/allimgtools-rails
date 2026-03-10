class ResizeImagesJob < ApplicationJob
  queue_as :default

  def perform(task_id, resizes:)
    task = Task.find_by!(task_id: task_id)

    task.uploads.completed.find_each do |upload|
      settings = resizes[upload.upload_id] || {}
      resize_upload(upload,
        width: settings["width"],
        height: settings["height"],
        maintain_aspect_ratio: settings["maintain_aspect_ratio"] != false
      )
    end

    task.update!(status: "done")
  rescue => e
    Task.find_by(task_id: task_id)&.update!(status: "failed")
    raise e
  end

  private

  def resize_upload(upload, width:, height:, maintain_aspect_ratio:)
    result = upload.file.open do |source|
      pipeline = ImageProcessing::Vips.source(source)

      pipeline = if maintain_aspect_ratio
        pipeline.resize_to_limit(width, height)
      else
        pipeline.resize_to_fill(width, height)
      end

      pipeline.call
    end

    upload.compressed_file.attach(
      io: result,
      filename: upload.filename,
      content_type: upload.file.content_type
    )
  end
end
