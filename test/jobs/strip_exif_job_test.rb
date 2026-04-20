require "test_helper"

class StripExifJobTest < ActiveSupport::TestCase
  def perform(task_id, **opts)
    StripExifJob.perform_now(task_id, **opts)
  end

  test "marks task done after stripping exif" do
    task   = create_task(tool: "exif")
    upload = create_upload(task: task)
    attach_test_image(upload)

    with_vips_stub do
      perform(task.task_id)
    end

    assert_equal "done", task.reload.status
  end

  test "marks task failed and re-raises on error" do
    task = create_task(tool: "exif")
    _upload = create_upload(task: task)

    job = StripExifJob.new
    job.stub(:strip_exif, ->(*) { raise "exif error" }) do
      assert_raises(RuntimeError) { job.perform(task.task_id) }
    end

    assert_equal "failed", task.reload.status
  end

  test "filters uploads by upload_ids when provided" do
    task = create_task(tool: "exif")
    u1   = create_upload(task: task)
    u2   = create_upload(task: task)
    attach_test_image(u1)
    attach_test_image(u2)

    processed = []
    job = StripExifJob.new
    job.stub(:strip_exif, ->(upload) { processed << upload.upload_id }) do
      job.perform(task.task_id, upload_ids: [ u1.upload_id ])
    end

    assert_includes processed, u1.upload_id
    assert_not_includes processed, u2.upload_id
  end

  test "strip_exif handles jpeg format" do
    task   = create_task(tool: "exif")
    upload = create_upload(task: task, filename: "photo.jpg")
    attach_test_image(upload, filename: "photo.jpg", content_type: "image/jpeg")

    with_vips_stub do
      perform(task.task_id)
    end

    assert_equal "done", task.reload.status
  end

  test "strip_exif handles webp format" do
    task   = create_task(tool: "exif")
    upload = create_upload(task: task, filename: "image.webp")
    attach_test_image(upload, filename: "image.webp", content_type: "image/webp")

    with_vips_stub do
      perform(task.task_id)
    end

    assert_equal "done", task.reload.status
  end

  test "strip_exif handles png format" do
    task   = create_task(tool: "exif")
    upload = create_upload(task: task, filename: "image.png")
    attach_test_image(upload)

    with_vips_stub do
      perform(task.task_id)
    end

    assert_equal "done", task.reload.status
  end

  test "strip_exif handles unknown format via else branch" do
    task   = create_task(tool: "exif")
    upload = create_upload(task: task, filename: "image.tiff")
    attach_test_image(upload, filename: "image.tiff", content_type: "image/png")

    with_vips_stub do
      perform(task.task_id)
    end

    assert_equal "done", task.reload.status
  end
end
