class UploadsController < ApplicationController
  MAX_FILENAME_LENGTH = 255
  MAX_CHUNK_SIZE      = 5 * 1024 * 1024 + 1.kilobyte  # 5MB + 1KB 여유
  MAX_CHUNKS          = (Upload::MAX_FILE_SIZE_PRO.to_f / (5 * 1024 * 1024)).ceil + 1

  def chunk
    upload_id    = params.require(:upload_id)
    chunk_index  = params.require(:chunk_index).to_i
    total_chunks = params.require(:total_chunks).to_i
    filename     = params[:filename].to_s
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

    max_size = Upload.max_size_for(Current.user)

    # 4. Validate actual chunk size (do not trust client-reported file_size)
    chunk_size = chunk_data.respond_to?(:size) ? chunk_data.size : chunk_data.bytesize
    if chunk_size > MAX_CHUNK_SIZE
      return render json: { error: "File size exceeds the limit." }, status: :unprocessable_entity
    end

    upload = Upload.find_by(upload_id: upload_id)

    if upload.nil?
      batch_limit = Task.batch_limit_for(Current.user)
      batch_count = Upload.where(task_id: task_id).where.not(status: "failed").count
      if batch_count >= batch_limit
        return render json: { error: "Batch limit (#{batch_limit} files) reached." }, status: :too_many_requests
      end

      upload = Upload.create!(
        upload_id:    upload_id,
        task_id:      task_id,
        filename:     filename,
        total_chunks: total_chunks,
        ip_address:   ip_address
      )
    end

    return render json: { error: "Upload already completed." }, status: :unprocessable_entity if upload.status == "done"

    unless chunk_index.between?(0, upload.total_chunks - 1)
      return render json: { error: "Invalid request." }, status: :bad_request
    end

    FileUtils.mkdir_p(upload.tmp_dir)
    chunk_bytes = chunk_data.respond_to?(:read) ? chunk_data.read : chunk_data
    File.binwrite(upload.chunk_path(chunk_index), chunk_bytes)

    upload.increment!(:chunks_received)

    if upload.chunks_received == upload.total_chunks
      upload.assemble!(max_size: max_size)
      render json: { status: "done", upload_id: upload_id, task_id: task_id }
    else
      render json: { status: "pending", received: upload.chunks_received, total: upload.total_chunks }
    end
  rescue => e
    Rails.logger.error "UploadsController#chunk error: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    render json: { error: "An error occurred. Please try again." }, status: :unprocessable_entity
  end
end
