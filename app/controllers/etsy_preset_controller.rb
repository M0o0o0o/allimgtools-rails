class EtsyPresetController < ApplicationController
  include ToolController

  VALID_FORMATS = %w[jpeg png].freeze

  def new
    @task = create_task
  end

  def start
    task       = find_task
    to_format  = VALID_FORMATS.include?(params[:to_format]) ? params[:to_format] : "jpeg"
    quality    = params[:quality].presence&.to_i&.clamp(1, 100) || 85
    strip_exif = params[:strip_exif] != "false"
    upload_ids = Array(params[:upload_ids]).presence

    task.update!(status: "processing")
    EtsyPresetImagesJob.perform_later(
      task.task_id,
      to_format: to_format,
      quality: quality,
      strip_exif: strip_exif,
      upload_ids: upload_ids
    )

    render_download_url(task)
  end
end
