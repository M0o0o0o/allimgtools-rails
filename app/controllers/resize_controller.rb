class ResizeController < ApplicationController
  include ToolController

  def new
    @task = create_task
  end

  MAX_DIMENSION = 4096

  def start
    task = find_task
    width = params[:width].presence&.to_i&.clamp(1, MAX_DIMENSION)
    height = params[:height].presence&.to_i&.clamp(1, MAX_DIMENSION)
    maintain_aspect_ratio = params[:maintain_aspect_ratio] != "false"

    upload_ids = Array(params[:upload_ids]).presence
    scope = upload_ids ? task.uploads.where(upload_id: upload_ids) : task.uploads
    resizes = scope.pluck(:upload_id).each_with_object({}) do |uid, h|
      h[uid] = {
        "width" => width,
        "height" => height,
        "maintain_aspect_ratio" => maintain_aspect_ratio
      }
    end

    task.update!(status: "processing")
    ResizeImagesJob.perform_later(task.task_id, resizes: resizes)

    render_download_url(task)
  end
end
