require "test_helper"

class CropImageJobTest < ActiveSupport::TestCase
  def perform(task_id, upload_id:, crop_x: 0, crop_y: 0, crop_width: 50, crop_height: 50)
    CropImageJob.perform_now(task_id,
      upload_id: upload_id,
      crop_x: crop_x, crop_y: crop_y,
      crop_width: crop_width, crop_height: crop_height)
  end

  test "marks task done after crop" do
    task   = create_task(tool: "crop")
    upload = create_upload(task: task)
    attach_test_image(upload)

    with_vips_stub do
      perform(task.task_id, upload_id: upload.upload_id)
    end

    assert_equal "done", task.reload.status
  end

  test "marks task failed and re-raises on error" do
    task   = create_task(tool: "crop")
    upload = create_upload(task: task)

    job = CropImageJob.new
    job.stub(:crop_upload, ->(*) { raise "crop error" }) do
      assert_raises(RuntimeError) do
        job.perform(task.task_id, upload_id: upload.upload_id,
                    crop_x: 0, crop_y: 0, crop_width: 50, crop_height: 50)
      end
    end

    assert_equal "failed", task.reload.status
  end

  test "raises RecordNotFound for unknown upload_id" do
    task = create_task(tool: "crop")

    assert_raises(ActiveRecord::RecordNotFound) do
      perform(task.task_id, upload_id: "ghost-id")
    end

    assert_equal "failed", task.reload.status
  end

  test "crop with non-zero origin coordinates" do
    task   = create_task(tool: "crop")
    upload = create_upload(task: task)
    attach_test_image(upload)

    with_vips_stub do
      perform(task.task_id, upload_id: upload.upload_id,
              crop_x: 10, crop_y: 10, crop_width: 20, crop_height: 20)
    end

    assert_equal "done", task.reload.status
  end
end
