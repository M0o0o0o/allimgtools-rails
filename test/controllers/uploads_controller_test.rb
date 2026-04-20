require "test_helper"

class UploadsControllerTest < ActionDispatch::IntegrationTest
  # ── Helpers ───────────────────────────────────────────────────────────────

  def post_chunk(overrides = {})
    task = overrides.delete(:task) || create_task
    defaults = {
      upload_id:    SecureRandom.uuid,
      chunk_index:  0,
      total_chunks: 1,
      filename:     "test.png",
      task_id:      task.task_id,
      chunk:        png_upload
    }
    post upload_chunk_path, params: defaults.merge(overrides)
    task
  end

  def png_upload(name: "test.png")
    tmp = Tempfile.new([ "upload_test", ".png" ])
    tmp.binmode
    tmp.write(MINIMAL_PNG)
    tmp.rewind
    ActionDispatch::Http::UploadedFile.new(
      tempfile: tmp,
      filename: name,
      type:     "image/png"
    )
  end

  # ── Validation: upload_id ─────────────────────────────────────────────────

  test "rejects invalid upload_id format" do
    post_chunk(upload_id: "not-a-uuid")
    assert_response :bad_request
    assert_match "Invalid request", response.parsed_body["error"]
  end

  test "accepts valid UUID upload_id" do
    post_chunk
    assert_response :success
  end

  # ── Validation: total_chunks ──────────────────────────────────────────────

  test "rejects total_chunks of 0" do
    task = create_task
    post upload_chunk_path, params: {
      upload_id: SecureRandom.uuid, chunk_index: 0, total_chunks: 0,
      filename: "test.png", task_id: task.task_id, chunk: png_upload
    }
    assert_response :bad_request
  end

  test "rejects total_chunks above MAX_CHUNKS" do
    max = UploadsController::MAX_CHUNKS + 1
    task = create_task
    post upload_chunk_path, params: {
      upload_id: SecureRandom.uuid, chunk_index: 0, total_chunks: max,
      filename: "test.png", task_id: task.task_id, chunk: png_upload
    }
    assert_response :bad_request
  end

  # ── Validation: filename ──────────────────────────────────────────────────

  test "rejects blank filename" do
    task = create_task
    post upload_chunk_path, params: {
      upload_id: SecureRandom.uuid, chunk_index: 0, total_chunks: 1,
      filename: "", task_id: task.task_id, chunk: png_upload
    }
    assert_response :bad_request
    assert_match "Invalid filename", response.parsed_body["error"]
  end

  test "rejects filename with null byte" do
    task = create_task
    post upload_chunk_path, params: {
      upload_id: SecureRandom.uuid, chunk_index: 0, total_chunks: 1,
      filename: "bad\x00name.jpg", task_id: task.task_id, chunk: png_upload
    }
    assert_response :bad_request
  end

  test "rejects filename exceeding 255 characters" do
    task = create_task
    post upload_chunk_path, params: {
      upload_id: SecureRandom.uuid, chunk_index: 0, total_chunks: 1,
      filename: "a" * 256 + ".png", task_id: task.task_id, chunk: png_upload
    }
    assert_response :bad_request
  end

  # ── Validation: chunk size ────────────────────────────────────────────────

  test "rejects oversized chunk" do
    oversize = "x" * (UploadsController::MAX_CHUNK_SIZE + 1)
    task = create_task
    post upload_chunk_path, params: {
      upload_id: SecureRandom.uuid, chunk_index: 0, total_chunks: 1,
      filename: "test.png", task_id: task.task_id,
      chunk: ActionDispatch::Http::UploadedFile.new(
        tempfile: StringIO.new(oversize), filename: "test.png", type: "image/png"
      )
    }
    assert_response :unprocessable_entity
    assert_match "exceeds the limit", response.parsed_body["error"]
  end

  # ── Batch limit ───────────────────────────────────────────────────────────

  test "respects free batch limit of 10" do
    task = create_task
    # Create 10 uploads already
    10.times { create_upload(task: task) }

    post_chunk(task: task, upload_id: SecureRandom.uuid)
    assert_response :too_many_requests
    assert_match "Batch limit", response.parsed_body["error"]
  end

  test "allows pro users up to 30 files" do
    sign_in_as(users(:pro_user))
    task = create_task

    # 29 existing uploads; the 30th should be allowed
    29.times { create_upload(task: task) }
    post_chunk(task: task)
    # Response is :success or :ok (not 429)
    assert_not_equal 429, response.status
  end

  test "rejects 31st file for pro user" do
    sign_in_as(users(:pro_user))
    task = create_task
    30.times { create_upload(task: task) }

    post_chunk(task: task, upload_id: SecureRandom.uuid)
    assert_response :too_many_requests
  end

  # ── Already completed upload ──────────────────────────────────────────────

  test "returns error when upload is already done" do
    task   = create_task
    upload = create_upload(task: task, status: "done")

    post upload_chunk_path, params: {
      upload_id:    upload.upload_id,
      chunk_index:  0,
      total_chunks: 1,
      filename:     upload.filename,
      task_id:      task.task_id,
      chunk:        png_upload
    }
    assert_response :unprocessable_entity
    assert_match "already completed", response.parsed_body["error"]
  end

  # ── Multi-chunk upload ────────────────────────────────────────────────────

  test "returns pending status when not all chunks received" do
    task      = create_task
    upload_id = SecureRandom.uuid

    post upload_chunk_path, params: {
      upload_id:    upload_id,
      chunk_index:  0,
      total_chunks: 2,
      filename:     "test.png",
      task_id:      task.task_id,
      chunk:        png_upload
    }

    assert_response :success
    assert_equal "pending", response.parsed_body["status"]
  end

  # ── Successful single-chunk upload ────────────────────────────────────────

  test "assembles and returns done when single chunk completes upload" do
    task      = create_task
    upload_id = SecureRandom.uuid

    post upload_chunk_path, params: {
      upload_id:    upload_id,
      chunk_index:  0,
      total_chunks: 1,
      filename:     "test.png",
      task_id:      task.task_id,
      chunk:        png_upload
    }

    assert_response :success
    body = response.parsed_body
    assert_equal "done", body["status"]
    assert_equal upload_id, body["upload_id"]
  ensure
    Upload.find_by(upload_id: upload_id)&.file&.purge
  end
end
