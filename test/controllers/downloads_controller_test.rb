require "test_helper"

class DownloadsControllerTest < ActionDispatch::IntegrationTest
  # ── show ─────────────────────────────────────────────────────────────────

  test "show renders for existing task" do
    task = create_task
    get download_path(task_id: task.task_id)
    assert_response :success
  end

  test "show returns 404 for unknown task_id" do
    get download_path(task_id: "nonexistent-task")
    assert_response :not_found
  end

  # ── zip ───────────────────────────────────────────────────────────────────

  test "zip streams a ZIP file with attached compressed files" do
    task   = create_task
    upload = create_upload(task: task)
    attach_test_image(upload)
    upload.compressed_file.attach(
      io:           StringIO.new(MINIMAL_PNG),
      filename:     "compressed.png",
      content_type: "image/png"
    )

    get download_zip_path(task_id: task.task_id)

    assert_response :success
    assert_equal "application/zip", response.content_type
    assert response.body.length > 0
  ensure
    upload&.file&.purge
    upload&.compressed_file&.purge
  end

  test "zip returns empty archive when no completed uploads have compressed files" do
    task = create_task
    create_upload(task: task, status: "pending")

    get download_zip_path(task_id: task.task_id)

    assert_response :success
    assert_equal "application/zip", response.content_type
  end
end
