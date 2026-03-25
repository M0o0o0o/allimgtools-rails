class ExifController < ApplicationController
  include ToolController

  def new
    @task = create_task
  end

  def start
    task = find_task
    upload_ids = Array(params[:upload_ids]).presence

    task.update!(status: "processing")
    StripExifJob.perform_later(task.task_id, upload_ids: upload_ids)

    render_download_url(task)
  end
end
