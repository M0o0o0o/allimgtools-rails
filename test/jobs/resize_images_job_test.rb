require "test_helper"

class ResizeImagesJobTest < ActiveSupport::TestCase
  def perform(task_id, resizes:)
    ResizeImagesJob.perform_now(task_id, resizes: resizes)
  end

  def resizes_for(upload, width: 100, height: 100, maintain: true)
    {
      upload.upload_id => {
        "width" => width, "height" => height, "maintain_aspect_ratio" => maintain
      }
    }
  end

  test "marks task done after processing" do
    task   = create_task(tool: "resize")
    upload = create_upload(task: task)
    attach_test_image(upload)

    with_vips_stub do
      perform(task.task_id, resizes: resizes_for(upload))
    end

    assert_equal "done", task.reload.status
  end

  test "marks task failed and re-raises on error" do
    task   = create_task(tool: "resize")
    upload = create_upload(task: task)

    job = ResizeImagesJob.new
    job.stub(:resize_upload, ->(*) { raise "resize failed" }) do
      assert_raises(RuntimeError) { job.perform(task.task_id, resizes: resizes_for(upload)) }
    end

    assert_equal "failed", task.reload.status
  end

  test "only processes uploads whose ids are in resizes keys" do
    task = create_task(tool: "resize")
    u1   = create_upload(task: task)
    u2   = create_upload(task: task)
    attach_test_image(u1)
    attach_test_image(u2)

    processed = []
    job = ResizeImagesJob.new
    job.stub(:resize_upload, ->(upload, **) { processed << upload.upload_id }) do
      job.perform(task.task_id, resizes: resizes_for(u1))
    end

    assert_includes processed, u1.upload_id
    assert_not_includes processed, u2.upload_id
  end

  test "resize with maintain_aspect_ratio false uses resize_to_fill" do
    task   = create_task(tool: "resize")
    upload = create_upload(task: task)
    attach_test_image(upload)

    with_vips_stub do
      perform(task.task_id, resizes: resizes_for(upload, maintain: false))
    end

    assert_equal "done", task.reload.status
  end

  test "resize with maintain_aspect_ratio true uses resize_to_limit" do
    task   = create_task(tool: "resize")
    upload = create_upload(task: task)
    attach_test_image(upload)

    with_vips_stub do
      perform(task.task_id, resizes: resizes_for(upload, maintain: true))
    end

    assert_equal "done", task.reload.status
  end
end
