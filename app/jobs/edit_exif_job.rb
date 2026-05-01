class EditExifJob < ApplicationJob
  queue_as :default

  CONTENT_TYPE_MAP = { "jpeg" => "image/jpeg", "png" => "image/png", "webp" => "image/webp", "gif" => "image/gif" }.freeze

  # edits: { upload_id => { "Artist" => "...", "GPSLatitude" => "37.5", ... }, ... }
  def perform(task_id, edits: {})
    task = Task.find_by!(task_id: task_id)

    task.uploads.completed.find_each do |upload|
      fields = edits[upload.upload_id] || {}
      write_exif(upload, fields)
    end

    task.update!(status: "done")
  rescue => e
    Task.find_by(task_id: task_id)&.update!(status: "failed")
    raise e
  end

  private

  def write_exif(upload, fields)
    ext = upload.normalized_extension

    Tempfile.create([ "exif_edit", ".#{ext}" ], binmode: true) do |tmp|
      upload.file.open do |source|
        tmp.write(source.read)
        tmp.flush
      end

      exif = MiniExiftool.new(tmp.path)

      fields.each do |tag, value|
        if value.blank?
          exif[tag] = nil
        else
          exif[tag] = coerce_value(tag, value)
        end
      end

      exif.save!

      upload.compressed_file.attach(
        io: File.open(tmp.path, "rb"),
        filename: upload.filename,
        content_type: CONTENT_TYPE_MAP.fetch(ext, upload.file.content_type)
      )
    end
  end

  def coerce_value(tag, value)
    case tag
    when "GPSLatitude", "GPSLongitude", "GPSAltitude"
      value.to_f
    when "Keywords"
      value.split(/\s*,\s*/).reject(&:blank?)
    else
      value.to_s
    end
  end
end
