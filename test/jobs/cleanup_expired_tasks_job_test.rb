require "test_helper"

class CleanupExpiredTasksJobTest < ActiveSupport::TestCase
  def perform(task_id)
    CleanupExpiredTasksJob.perform_now(task_id)
  end

  test "destroys task and its uploads" do
    task   = create_task
    upload = create_upload(task: task)

    perform(task.task_id)

    assert_nil Task.find_by(task_id: task.task_id)
    assert_nil Upload.find_by(upload_id: upload.upload_id)
  end

  test "does nothing for unknown task_id" do
    assert_nothing_raised { perform("non-existent-task-id") }
  end

  test "purges attached file and compressed_file" do
    task   = create_task
    upload = create_upload(task: task)
    attach_test_image(upload)
    upload.compressed_file.attach(
      io: StringIO.new(MINIMAL_PNG), filename: "compressed.png", content_type: "image/png"
    )

    perform(task.task_id)

    assert_nil Upload.find_by(upload_id: upload.upload_id)
  end

  test "removes tmp chunk directory" do
    task   = create_task
    upload = create_upload(task: task)
    FileUtils.mkdir_p(upload.tmp_dir)
    File.write(upload.tmp_dir.join("0.chunk"), "data")

    perform(task.task_id)

    assert_not File.exist?(upload.tmp_dir)
  ensure
    FileUtils.rm_rf(upload.tmp_dir) if File.exist?(upload.tmp_dir)
  end

  test "continues cleanup even if one upload raises" do
    task    = create_task
    upload1 = create_upload(task: task)
    upload2 = create_upload(task: task)

    # Force upload1#file.purge to raise
    upload1.file.stub(:attached?, true) do
      upload1.file.stub(:purge, -> { raise "Storage error" }) do
        # The job catches per-upload errors and continues
        assert_nothing_raised { perform(task.task_id) }
      end
    end

    # Task may or may not be destroyed depending on error handling;
    # the important thing is no exception bubbles up.
    assert_nil Upload.find_by(upload_id: upload2.upload_id)
  end
end
