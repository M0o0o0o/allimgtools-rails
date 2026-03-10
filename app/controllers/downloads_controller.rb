class DownloadsController < ApplicationController
  before_action :set_task

  def show
    @uploads = @task.uploads.completed.with_attached_file.with_attached_compressed_file
  end

  def zip
    uploads = @task.uploads.completed.with_attached_compressed_file.select { |u| u.compressed_file.attached? }

    zip_data = Zip::OutputStream.write_buffer do |zip|
      uploads.each do |upload|
        upload.compressed_file.open do |f|
          zip.put_next_entry(upload.compressed_file.filename.to_s)
          zip.write(f.read)
        end
      end
    end

    zip_data.rewind
    send_data zip_data.read,
              type: "application/zip",
              filename: "compressed_#{@task.task_id[0..7]}.zip",
              disposition: "attachment"
  end

  private

  def set_task
    @task = Task.find_by!(task_id: params[:task_id])
  end
end
