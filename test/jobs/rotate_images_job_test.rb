require "test_helper"

class RotateImagesJobTest < ActiveSupport::TestCase
  def perform(task_id, upload_id:, rotate:)
    RotateImagesJob.perform_now(task_id, upload_id: upload_id, rotate: rotate)
  end

  test "marks task done after rotation" do
    task   = create_task(tool: "rotate")
    upload = create_upload(task: task)
    attach_test_image(upload)

    with_vips_stub do
      perform(task.task_id, upload_id: upload.upload_id, rotate: 90)
    end

    assert_equal "done", task.reload.status
  end

  test "marks task failed and re-raises on error" do
    task   = create_task(tool: "rotate")
    upload = create_upload(task: task)

    job = RotateImagesJob.new
    job.stub(:rotate_upload, ->(*) { raise "rotate error" }) do
      assert_raises(RuntimeError) { job.perform(task.task_id, upload_id: upload.upload_id, rotate: 90) }
    end

    assert_equal "failed", task.reload.status
  end

  test "rotate 180 degrees" do
    task   = create_task(tool: "rotate")
    upload = create_upload(task: task)
    attach_test_image(upload)

    with_vips_stub do
      perform(task.task_id, upload_id: upload.upload_id, rotate: 180)
    end

    assert_equal "done", task.reload.status
  end

  test "rotate 270 degrees" do
    task   = create_task(tool: "rotate")
    upload = create_upload(task: task)
    attach_test_image(upload)

    with_vips_stub do
      perform(task.task_id, upload_id: upload.upload_id, rotate: 270)
    end

    assert_equal "done", task.reload.status
  end

  test "rotate 0 degrees (no-op branch)" do
    task   = create_task(tool: "rotate")
    upload = create_upload(task: task)
    attach_test_image(upload)

    with_vips_stub do
      perform(task.task_id, upload_id: upload.upload_id, rotate: 0)
    end

    assert_equal "done", task.reload.status
  end

  test "raises ActiveRecord::RecordNotFound for unknown upload_id" do
    task = create_task(tool: "rotate")

    assert_raises(ActiveRecord::RecordNotFound) do
      perform(task.task_id, upload_id: "nonexistent-uid", rotate: 90)
    end

    assert_equal "failed", task.reload.status
  end
end
