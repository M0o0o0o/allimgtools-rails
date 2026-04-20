require "test_helper"

class CompressControllerTest < ActionDispatch::IntegrationTest
  test "new creates a task and renders" do
    get new_compress_path
    assert_response :success
  end

  test "start dispatches CompressImagesJob and returns download URL" do
    task = create_task(tool: "compress")

    assert_enqueued_with(job: CompressImagesJob) do
      post start_compress_path, params: {
        task_id:    task.task_id,
        quality:    80,
        upload_ids: [ SecureRandom.uuid ],
        strip_exif: "false"
      }
    end

    assert_response :success
    assert_match task.task_id, response.parsed_body["download_url"]
    assert_equal "processing", task.reload.status
  end

  test "start clamps quality to 1–100" do
    task = create_task(tool: "compress")

    assert_enqueued_with(job: CompressImagesJob, args: [ task.task_id, { quality: 1,
                                                                          upload_ids: nil,
                                                                          strip_exif: false } ]) do
      post start_compress_path, params: { task_id: task.task_id, quality: -50 }
    end
  end

  test "start passes strip_exif: true when param is 'true'" do
    task = create_task(tool: "compress")

    assert_enqueued_with(job: CompressImagesJob) do
      post start_compress_path, params: { task_id: task.task_id, quality: 80, strip_exif: "true" }
    end
  end
end
