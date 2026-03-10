class CleanupExpiredTasksJob < ApplicationJob
  queue_as :default

  def perform(task_id)
    task = Task.find_by(task_id: task_id)
    return unless task

    task.uploads.find_each do |upload|
      upload.file.purge if upload.file.attached?
      upload.compressed_file.purge if upload.compressed_file.attached?
      FileUtils.rm_rf(upload.tmp_dir)
    end
    task.uploads.delete_all
    task.destroy
  end
end
