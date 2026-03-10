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

  MAX_FILE_SIZE = 5.megabytes

  def assemble!
    total_size = total_chunks.times.sum { |i| File.size(chunk_path(i)) }
    raise "파일 크기가 5MB를 초과합니다." if total_size > MAX_FILE_SIZE

    update!(status: "assembling")

    Tempfile.open([ "upload", File.extname(filename) ], binmode: true) do |output|
      total_chunks.times do |i|
        output.write(File.binread(chunk_path(i)))
      end
      output.rewind

      content_type = Marcel::MimeType.for(output, name: filename)
      raise "허용되지 않는 파일 형식입니다." unless ALLOWED_TYPES.include?(content_type)

      file.attach(io: output, filename: filename, content_type: content_type)
    end

    update!(status: "done")
    FileUtils.rm_rf(tmp_dir)
  rescue => e
    update!(status: "failed")
    FileUtils.rm_rf(tmp_dir)
    raise e
  end
end
