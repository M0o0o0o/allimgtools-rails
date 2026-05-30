class Upload < ApplicationRecord
  belongs_to :task, foreign_key: :task_id, primary_key: :task_id
  has_one_attached :file
  has_one_attached :compressed_file

  ALLOWED_TYPES = %w[image/jpeg image/png image/gif image/webp image/avif].freeze

  scope :completed, -> { where(status: "done") }

  def normalized_extension
    ext = File.extname(filename).delete_prefix(".").downcase
    ext == "jpg" ? "jpeg" : ext
  end

  def tmp_dir
    Rails.root.join("tmp", "chunks", upload_id)
  end

  def chunk_path(index)
    tmp_dir.join("#{index}.chunk")
  end

  MAX_FILE_SIZE     = 10.megabytes
  MAX_FILE_SIZE_PRO = 30.megabytes

  def self.max_size_for(user)
    user&.subscribed? ? MAX_FILE_SIZE_PRO : MAX_FILE_SIZE
  end

  def assemble!(max_size: MAX_FILE_SIZE)
    claimed = self.class.where(id: id, status: "pending").update_all(status: "assembling")
    return if claimed == 0

    reload

    total_size = total_chunks.times.sum { |i| File.size(chunk_path(i)) }
    raise "File size exceeds limit." if total_size > max_size

    Tempfile.open([ "upload", File.extname(filename) ], binmode: true) do |output|
      total_chunks.times do |i|
        IO.copy_stream(chunk_path(i).to_s, output)
      end
      output.rewind

      content_type = Marcel::MimeType.for(output, name: filename)
      raise "File type not allowed." unless ALLOWED_TYPES.include?(content_type)

      file.attach(io: output, filename: filename, content_type: content_type)
    end

    file.blob.analyze_later

    update!(status: "done")
    FileUtils.rm_rf(tmp_dir)
  rescue => e
    update!(status: "failed")
    file.purge if file.attached?
    compressed_file.purge if compressed_file.attached?
    FileUtils.rm_rf(tmp_dir)
    raise e
  end
end
