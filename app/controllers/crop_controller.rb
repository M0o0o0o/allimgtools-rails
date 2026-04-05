class CropController < ApplicationController
  include ToolController

  def new
    @task = create_task
  end

  def start
    task = find_task
    upload_id   = params[:upload_id].presence
    crop_x      = params[:crop_x].to_i
    crop_y      = params[:crop_y].to_i
    crop_width  = params[:crop_width].to_i
    crop_height = params[:crop_height].to_i

    unless upload_id
      return render json: { error: "No image uploaded." }, status: :unprocessable_entity
    end

    if crop_width <= 0 || crop_height <= 0
      return render json: { error: "Invalid crop dimensions." }, status: :unprocessable_entity
    end

    task.update!(status: "processing")
    CropImageJob.perform_later(task.task_id,
      upload_id: upload_id,
      crop_x: crop_x, crop_y: crop_y,
      crop_width: crop_width, crop_height: crop_height)

    render_download_url(task)
  end
end
