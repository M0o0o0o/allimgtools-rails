class UploadsController < ApplicationController
  MAX_FILENAME_LENGTH = 255
  MAX_CHUNKS = (Upload::MAX_FILE_SIZE.to_f / (2 * 1024 * 1024)).ceil + 1

  def chunk
    upload_id    = params.require(:upload_id)
    chunk_index  = params.require(:chunk_index).to_i
    total_chunks = params.require(:total_chunks).to_i
    filename     = params.require(:filename)
    chunk_data   = params.require(:chunk)
    task_id      = params.require(:task_id)
    ip_address   = request.remote_ip

    # 1. Validate upload_id UUID format (prevent path traversal)
    unless upload_id.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
      return render json: { error: "Invalid request." }, status: :bad_request
    end

    # 2. Validate total_chunks upper bound
    if total_chunks < 1 || total_chunks > MAX_CHUNKS
      return render json: { error: "Invalid request." }, status: :bad_request
    end

    # 3. Validate filename
    if filename.blank? || filename.length > MAX_FILENAME_LENGTH || filename.include?("\x00")
      return render json: { error: "Invalid filename." }, status: :bad_request
    end

    # 4. Validate actual chunk size (do not trust client-reported file_size)
    if chunk_data.size > Upload::MAX_FILE_SIZE
      return render json: { error: "File size exceeds 5MB." }, status: :unprocessable_entity
    end

    upload = Upload.find_by(upload_id: upload_id)

    if upload.nil?
      return render json: { error: "Daily upload limit (#{Task::DAILY_UPLOAD_LIMIT} files) exceeded." }, status: :too_many_requests if Task.limit_reached?(ip_address)

      upload = Upload.create!(
        upload_id:    upload_id,
        task_id:      task_id,
        filename:     filename,
        total_chunks: total_chunks,
        ip_address:   ip_address
      )
    end

    return render json: { error: "Upload already completed." }, status: :unprocessable_entity if upload.status == "done"

    FileUtils.mkdir_p(upload.tmp_dir)
    File.binwrite(upload.chunk_path(chunk_index), chunk_data.read)

    saved_count = Dir.glob(upload.tmp_dir.join("*.chunk")).count

    if saved_count == total_chunks
      upload.assemble!
      render json: { status: "done", upload_id: upload_id, task_id: task_id }
    else
      render json: { status: "pending", received: saved_count, total: total_chunks }
    end
  rescue => e
    Rails.logger.error "UploadsController#chunk error: #{e.class}: #{e.message}"
    render json: { error: "An error occurred. Please try again." }, status: :unprocessable_entity
  end
end
