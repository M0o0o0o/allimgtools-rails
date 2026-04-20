require "test_helper"

class RotateControllerTest < ActionDispatch::IntegrationTest
  test "new creates a task and renders" do
    get new_rotate_path
    assert_response :success
  end

  test "start dispatches RotateImagesJob and returns download URL" do
    task   = create_task(tool: "rotate")
    upload = create_upload(task: task)

    assert_enqueued_with(job: RotateImagesJob) do
      post start_rotate_path, params: {
        task_id:   task.task_id,
        upload_id: upload.upload_id,
        rotate:    90
      }
    end

    assert_response :success
    assert_match task.task_id, response.parsed_body["download_url"]
  end

  test "start returns error when upload_id is missing" do
    task = create_task(tool: "rotate")

    post start_rotate_path, params: { task_id: task.task_id, rotate: 90 }

    assert_response :unprocessable_entity
    assert_match "No image uploaded", response.parsed_body["error"]
  end
end
