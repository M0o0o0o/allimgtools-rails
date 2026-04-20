require "test_helper"

class CropControllerTest < ActionDispatch::IntegrationTest
  test "new creates a task and renders" do
    get new_crop_path
    assert_response :success
  end

  test "start dispatches CropImageJob and returns download URL" do
    task   = create_task(tool: "crop")
    upload = create_upload(task: task)

    assert_enqueued_with(job: CropImageJob) do
      post start_crop_path, params: {
        task_id:     task.task_id,
        upload_id:   upload.upload_id,
        crop_x:      0,
        crop_y:      0,
        crop_width:  200,
        crop_height: 150
      }
    end

    assert_response :success
    assert_match task.task_id, response.parsed_body["download_url"]
  end

  test "start returns error when upload_id is missing" do
    task = create_task(tool: "crop")

    post start_crop_path, params: {
      task_id: task.task_id, crop_width: 100, crop_height: 100
    }

    assert_response :unprocessable_entity
    assert_match "No image uploaded", response.parsed_body["error"]
  end

  test "start returns error when crop_width is 0" do
    task   = create_task(tool: "crop")
    upload = create_upload(task: task)

    post start_crop_path, params: {
      task_id:     task.task_id,
      upload_id:   upload.upload_id,
      crop_width:  0,
      crop_height: 100
    }

    assert_response :unprocessable_entity
    assert_match "Invalid crop dimensions", response.parsed_body["error"]
  end

  test "start returns error when crop_height is 0" do
    task   = create_task(tool: "crop")
    upload = create_upload(task: task)

    post start_crop_path, params: {
      task_id:     task.task_id,
      upload_id:   upload.upload_id,
      crop_width:  100,
      crop_height: 0
    }

    assert_response :unprocessable_entity
    assert_match "Invalid crop dimensions", response.parsed_body["error"]
  end
end
