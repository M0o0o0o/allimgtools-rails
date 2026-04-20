require "test_helper"

class ConvertControllerTest < ActionDispatch::IntegrationTest
  test "new renders without explicit format" do
    get new_convert_path
    assert_response :success
  end

  test "new with valid to_format sets @to_format" do
    get new_convert_path, params: { to_format: "webp" }
    assert_response :success
  end

  test "new with invalid to_format ignores it" do
    get new_convert_path, params: { to_format: "bmp" }
    assert_response :success
  end

  test "start dispatches ConvertImagesJob with valid format" do
    task = create_task(tool: "convert")

    assert_enqueued_with(job: ConvertImagesJob) do
      post start_convert_path, params: {
        task_id:    task.task_id,
        to_format:  "webp",
        upload_ids: [ SecureRandom.uuid ]
      }
    end

    assert_response :success
    assert_match task.task_id, response.parsed_body["download_url"]
    assert_equal "processing", task.reload.status
  end

  test "start returns error for invalid format" do
    task = create_task(tool: "convert")

    post start_convert_path, params: { task_id: task.task_id, to_format: "bmp" }

    assert_response :unprocessable_entity
    assert_match "Invalid format", response.parsed_body["error"]
  end

  test "start returns error when to_format is missing" do
    task = create_task(tool: "convert")

    post start_convert_path, params: { task_id: task.task_id }

    assert_response :unprocessable_entity
  end

  test "jpg-to-webp route sets to_format and from_format" do
    get jpg_to_webp_path
    assert_response :success
  end

  test "png-to-jpg route renders" do
    get png_to_jpg_path
    assert_response :success
  end
end
