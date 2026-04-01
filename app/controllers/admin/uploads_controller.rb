module Admin
  class UploadsController < BaseController
    ALLOWED_TYPES = %w[image/jpeg image/png image/gif image/webp image/avif].freeze
    MAX_SIZE = 10.megabytes

    def index
      blobs = ActiveStorage::Blob
        .where(content_type: ALLOWED_TYPES)
        .order(created_at: :desc)
        .limit(100)

      render json: blobs.map { |blob|
        {
          url: rails_blob_url(blob, only_path: true),
          sgid: blob.attachable_sgid,
          filename: blob.filename.to_s,
          filesize: blob.byte_size,
          content_type: blob.content_type
        }
      }
    end

    def create
      uploaded = params[:file]

      return render json: { error: "No file." }, status: :bad_request if uploaded.blank?
      return render json: { error: "File too large." }, status: :unprocessable_entity if uploaded.size > MAX_SIZE

      content_type = Marcel::MimeType.for(uploaded.tempfile, name: uploaded.original_filename)
      unless ALLOWED_TYPES.include?(content_type)
        return render json: { error: "File type not allowed." }, status: :unprocessable_entity
      end

      file = ImageProcessor.process(uploaded)
      checksum = OpenSSL::Digest::MD5.file(file.tempfile.path).base64digest

      blob = ActiveStorage::Blob.find_by(checksum: checksum) ||
             ActiveStorage::Blob.create_and_upload!(
               io: file,
               filename: file.original_filename,
               content_type: file.content_type
             )

      render json: {
        url: rails_blob_url(blob, only_path: true),
        sgid: blob.attachable_sgid,
        filename: blob.filename.to_s,
        filesize: blob.byte_size,
        content_type: blob.content_type
      }
    rescue => e
      Rails.logger.error "Admin::UploadsController#create error: #{e.class}: #{e.message}"
      render json: { error: "Upload failed." }, status: :unprocessable_entity
    end
  end
end
