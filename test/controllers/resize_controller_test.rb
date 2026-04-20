require "test_helper"

class ResizeControllerTest < ActionDispatch::IntegrationTest
  test "new creates a task and renders" do
    get new_resize_path
    assert_response :success
  end

  test "start dispatches ResizeImagesJob and returns download URL" do
    task   = create_task(tool: "resize")
    upload = create_upload(task: task)

    assert_enqueued_with(job: ResizeImagesJob) do
      post start_resize_path, params: {
        task_id:              task.task_id,
        width:                800,
        height:               600,
        maintain_aspect_ratio: "true",
        upload_ids:           [ upload.upload_id ]
      }
    end

    assert_response :success
    assert_match task.task_id, response.parsed_body["download_url"]
    assert_equal "processing", task.reload.status
  end

  test "start clamps width and height to MAX_DIMENSION" do
    task   = create_task(tool: "resize")
    create_upload(task: task)

    assert_enqueued_with(job: ResizeImagesJob) do
      post start_resize_path, params: {
        task_id: task.task_id, width: 99_999, height: 99_999
      }
    end
  end

  test "start accepts blank width and height" do
    task = create_task(tool: "resize")
    create_upload(task: task)

    assert_enqueued_with(job: ResizeImagesJob) do
      post start_resize_path, params: { task_id: task.task_id }
    end

    assert_response :success
  end

  test "start with maintain_aspect_ratio false" do
    task   = create_task(tool: "resize")
    upload = create_upload(task: task)

    assert_enqueued_with(job: ResizeImagesJob) do
      post start_resize_path, params: {
        task_id:               task.task_id,
        width:                 200,
        height:                200,
        maintain_aspect_ratio: "false",
        upload_ids:            [ upload.upload_id ]
      }
    end
  end
end
