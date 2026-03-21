class ConvertImagesJob < ApplicationJob
  queue_as :default

  EXTENSION_MAP = { "jpeg" => "jpg", "png" => "png", "webp" => "webp" }.freeze
  CONTENT_TYPE_MAP = { "jpeg" => "image/jpeg", "png" => "image/png", "webp" => "image/webp" }.freeze

  def perform(task_id, to_format:)
    task = Task.find_by!(task_id: task_id)

    task.uploads.completed.find_each do |upload|
      convert_upload(upload, to_format: to_format)
    end

    task.update!(status: "done")
  rescue => e
    Task.find_by(task_id: task_id)&.update!(status: "failed")
    raise e
  end

  private

  def convert_upload(upload, to_format:)
    result = upload.file.open do |source|
      ImageProcessing::Vips
        .source(source)
        .convert(to_format)
        .call
    end

    ext          = EXTENSION_MAP.fetch(to_format, to_format)
    new_filename = "#{File.basename(upload.filename, '.*')}.#{ext}"
    content_type = CONTENT_TYPE_MAP.fetch(to_format, "image/#{to_format}")

    upload.compressed_file.attach(
      io: result,
      filename: new_filename,
      content_type: content_type
    )
  end
end
