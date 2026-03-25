class RotateController < ApplicationController
  include ToolController

  def new
    @task = create_task
  end

  def start
    task = find_task
    upload_id = params[:upload_id].presence
    rotate = params[:rotate].to_i

    unless upload_id
      return render json: { error: "No image uploaded." }, status: :unprocessable_entity
    end

    task.update!(status: "processing")
    RotateImagesJob.perform_later(task.task_id, upload_id: upload_id, rotate: rotate)

    render_download_url(task)
  end
end
