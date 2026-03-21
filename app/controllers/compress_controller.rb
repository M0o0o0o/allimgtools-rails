class CompressController < ApplicationController
  include ToolController

  def new
    @task = create_task
  end

  def start
    task = find_task
    quality = params[:quality].to_i.clamp(1, 100)
    upload_ids = Array(params[:upload_ids]).presence

    task.update!(status: "processing")
    CompressImagesJob.perform_later(task.task_id, quality: quality, upload_ids: upload_ids)

    render_download_url(task)
  end
end
