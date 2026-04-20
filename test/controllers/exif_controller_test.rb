require "test_helper"

class ExifControllerTest < ActionDispatch::IntegrationTest
  test "new creates a task and renders" do
    get new_exif_path
    assert_response :success
  end

  test "start dispatches StripExifJob and returns download URL" do
    task   = create_task(tool: "exif")
    upload = create_upload(task: task)

    assert_enqueued_with(job: StripExifJob) do
      post start_exif_path, params: {
        task_id:    task.task_id,
        upload_ids: [ upload.upload_id ]
      }
    end

    assert_response :success
    assert_match task.task_id, response.parsed_body["download_url"]
    assert_equal "processing", task.reload.status
  end

  test "start without upload_ids processes all uploads" do
    task = create_task(tool: "exif")

    assert_enqueued_with(job: StripExifJob) do
      post start_exif_path, params: { task_id: task.task_id }
    end

    assert_response :success
  end
end
