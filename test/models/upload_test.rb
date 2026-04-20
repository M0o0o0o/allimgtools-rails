require "test_helper"

class UploadTest < ActiveSupport::TestCase
  # ── Constants ────────────────────────────────────────────────────────────

  test "MAX_FILE_SIZE is 10 MB" do
    assert_equal 10.megabytes, Upload::MAX_FILE_SIZE
  end

  test "MAX_FILE_SIZE_PRO is 30 MB" do
    assert_equal 30.megabytes, Upload::MAX_FILE_SIZE_PRO
  end

  # ── max_size_for ─────────────────────────────────────────────────────────

  test "max_size_for returns pro limit for subscribed user" do
    assert_equal Upload::MAX_FILE_SIZE_PRO, Upload.max_size_for(users(:pro_user))
  end

  test "max_size_for returns free limit for unsubscribed user" do
    assert_equal Upload::MAX_FILE_SIZE, Upload.max_size_for(users(:free_user))
  end

  test "max_size_for returns free limit for nil" do
    assert_equal Upload::MAX_FILE_SIZE, Upload.max_size_for(nil)
  end

  test "max_size_for returns free limit for expired subscription" do
    assert_equal Upload::MAX_FILE_SIZE, Upload.max_size_for(users(:expired_user))
  end

  # ── normalized_extension ─────────────────────────────────────────────────

  test "normalized_extension converts jpg to jpeg" do
    assert_equal "jpeg", Upload.new(filename: "photo.jpg").normalized_extension
  end

  test "normalized_extension returns png" do
    assert_equal "png", Upload.new(filename: "image.png").normalized_extension
  end

  test "normalized_extension returns webp" do
    assert_equal "webp", Upload.new(filename: "image.webp").normalized_extension
  end

  test "normalized_extension returns avif" do
    assert_equal "avif", Upload.new(filename: "image.avif").normalized_extension
  end

  test "normalized_extension returns gif" do
    assert_equal "gif", Upload.new(filename: "image.gif").normalized_extension
  end

  test "normalized_extension is downcased" do
    assert_equal "png", Upload.new(filename: "IMAGE.PNG").normalized_extension
  end

  # ── tmp_dir / chunk_path ─────────────────────────────────────────────────

  test "tmp_dir returns path under tmp/chunks" do
    upload = Upload.new(upload_id: "abc-123")
    assert_equal Rails.root.join("tmp", "chunks", "abc-123"), upload.tmp_dir
  end

  test "chunk_path returns indexed path under tmp_dir" do
    upload = Upload.new(upload_id: "abc-123")
    assert_equal Rails.root.join("tmp", "chunks", "abc-123", "2.chunk"), upload.chunk_path(2)
  end

  # ── completed scope ───────────────────────────────────────────────────────

  test "completed scope returns only done uploads" do
    task = create_task
    done    = create_upload(task: task, status: "done")
    _pending = create_upload(task: task, status: "pending")
    _failed  = create_upload(task: task, status: "failed")

    ids = task.uploads.completed.pluck(:upload_id)
    assert_includes ids, done.upload_id
    assert_equal 1, ids.size
  end

  # ── assemble! ────────────────────────────────────────────────────────────

  test "assemble! raises and marks failed when file size exceeds limit" do
    task   = create_task
    upload = create_upload(task: task, status: "pending", filename: "test.png")

    FileUtils.mkdir_p(upload.tmp_dir)
    File.binwrite(upload.chunk_path(0), "x" * 200)

    error = assert_raises(RuntimeError) { upload.assemble!(max_size: 100) }
    assert_match(/exceeds limit/, error.message)
    assert_equal "failed", upload.reload.status
  ensure
    FileUtils.rm_rf(upload.tmp_dir) if upload
  end

  test "assemble! raises and marks failed for disallowed MIME type" do
    task   = create_task
    upload = create_upload(task: task, status: "pending", filename: "test.txt")

    FileUtils.mkdir_p(upload.tmp_dir)
    File.binwrite(upload.chunk_path(0), "plain text content here")

    assert_raises(RuntimeError) { upload.assemble! }
    assert_equal "failed", upload.reload.status
  ensure
    FileUtils.rm_rf(upload.tmp_dir) if upload
  end

  test "assemble! succeeds with valid PNG data and attaches file" do
    task   = create_task
    upload = create_upload(task: task, status: "pending", filename: "test.png")

    FileUtils.mkdir_p(upload.tmp_dir)
    File.binwrite(upload.chunk_path(0), MINIMAL_PNG)

    upload.assemble!

    assert_equal "done", upload.reload.status
    assert upload.file.attached?
  ensure
    upload.file.purge if upload&.file&.attached?
    FileUtils.rm_rf(upload.tmp_dir) if upload
  end
end
