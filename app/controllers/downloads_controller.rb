class DownloadsController < ApplicationController
  before_action :set_task

  def show
    @uploads = @task.uploads.completed.with_attached_file.with_attached_compressed_file
  end

  def zip
    uploads = @task.uploads.completed.with_attached_compressed_file.select { |u| u.compressed_file.attached? }

    response.headers["Content-Type"] = "application/zip"
    response.headers["Content-Disposition"] = "attachment; filename=\"compressed_#{@task.task_id[0..7]}.zip\""

    writer = ZipTricks::Streamer.new(response.stream)
    uploads.each do |upload|
      filename = File.basename(upload.compressed_file.filename.to_s)
      size = upload.compressed_file.byte_size
      writer.write_stored_file(filename) do |sink|
        upload.compressed_file.open do |f|
          IO.copy_stream(f, sink)
        end
      end
    end
    writer.close
  ensure
    response.stream.close
  end

  private

  def set_task
    @task = Task.find_by!(task_id: params[:task_id])
  end
end
