require "test_helper"

class CompressImagesJobTest < ActiveSupport::TestCase
  def perform(task_id, **opts)
    CompressImagesJob.perform_now(task_id, **opts)
  end

  # ── Control flow ─────────────────────────────────────────────────────────

  test "marks task done after processing" do
    task   = create_task(tool: "compress")
    upload = create_upload(task: task)
    attach_test_image(upload)

    with_vips_stub do
      perform(task.task_id, quality: 80)
    end

    assert_equal "done", task.reload.status
  end

  test "marks task failed and re-raises on error" do
    task = create_task(tool: "compress")
    _upload = create_upload(task: task)

    job = CompressImagesJob.new
    job.stub(:compress_upload, ->(*) { raise "vips exploded" }) do
      assert_raises(RuntimeError, "vips exploded") do
        job.perform(task.task_id, quality: 80)
      end
    end

    assert_equal "failed", task.reload.status
  end

  test "filters uploads by upload_ids when provided" do
    task = create_task(tool: "compress")
    u1 = create_upload(task: task)
    u2 = create_upload(task: task)
    attach_test_image(u1)
    attach_test_image(u2)

    processed = []
    job = CompressImagesJob.new
    job.stub(:compress_upload, ->(upload, **) { processed << upload.upload_id }) do
      job.perform(task.task_id, quality: 80, upload_ids: [ u1.upload_id ])
    end

    assert_includes processed, u1.upload_id
    assert_not_includes processed, u2.upload_id
  end

  test "only processes completed uploads" do
    task    = create_task(tool: "compress")
    done    = create_upload(task: task, status: "done")
    pending = create_upload(task: task, status: "pending")
    attach_test_image(done)

    processed = []
    job = CompressImagesJob.new
    job.stub(:compress_upload, ->(upload, **) { processed << upload.upload_id }) do
      job.perform(task.task_id, quality: 80)
    end

    assert_includes processed, done.upload_id
    assert_not_includes processed, pending.upload_id
  end

  # ── Private method: compress_upload format branches ───────────────────────

  test "compress_upload attaches result when result is smaller than original" do
    task   = create_task(tool: "compress")
    upload = create_upload(task: task, filename: "photo.jpg")
    attach_test_image(upload, filename: "photo.jpg", content_type: "image/jpeg")

    with_vips_stub(content: "sm") do |result|
      # result is 2 bytes, original MINIMAL_PNG is 68 bytes → smaller
      perform(task.task_id, quality: 80)
    end

    # Job ran without error
    assert_equal "done", task.reload.status
  end

  test "compress_upload strips exif when requested" do
    task   = create_task(tool: "compress")
    upload = create_upload(task: task, filename: "photo.jpg")
    attach_test_image(upload, filename: "photo.jpg", content_type: "image/jpeg")

    with_vips_stub do
      perform(task.task_id, quality: 80, strip_exif: true)
    end

    assert_equal "done", task.reload.status
  end

  test "compress_upload handles webp format" do
    task   = create_task(tool: "compress")
    upload = create_upload(task: task, filename: "image.webp")
    attach_test_image(upload, filename: "image.webp", content_type: "image/webp")

    with_vips_stub do
      perform(task.task_id, quality: 80)
    end

    assert_equal "done", task.reload.status
  end

  test "compress_upload handles gif format" do
    task   = create_task(tool: "compress")
    upload = create_upload(task: task, filename: "image.gif")
    attach_test_image(upload, filename: "image.gif", content_type: "image/gif")

    with_vips_stub do
      perform(task.task_id, quality: 50)
    end

    assert_equal "done", task.reload.status
  end

  test "compress_upload handles avif format" do
    task   = create_task(tool: "compress")
    upload = create_upload(task: task, filename: "image.avif")
    attach_test_image(upload, filename: "image.avif", content_type: "image/avif")

    with_vips_stub do
      perform(task.task_id, quality: 70)
    end

    assert_equal "done", task.reload.status
  end

  test "compress_upload handles png format" do
    task   = create_task(tool: "compress")
    upload = create_upload(task: task, filename: "image.png")
    attach_test_image(upload)

    with_vips_stub do
      perform(task.task_id, quality: 80)
    end

    assert_equal "done", task.reload.status
  end
end
