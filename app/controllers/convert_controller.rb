class ConvertController < ApplicationController
  include ToolController

  VALID_FORMATS = %w[jpeg png webp avif].freeze

  def new
    @task        = create_task
    @to_format   = VALID_FORMATS.include?(params[:to_format])   ? params[:to_format]   : nil
    @from_format = params[:from_format].presence
  end

  def start
    task      = find_task
    to_format = params[:to_format].presence

    unless VALID_FORMATS.include?(to_format)
      return render json: { error: "Invalid format." }, status: :unprocessable_entity
    end

    upload_ids = Array(params[:upload_ids]).presence

    task.update!(status: "processing")
    ConvertImagesJob.perform_later(task.task_id, to_format: to_format, upload_ids: upload_ids)

    render_download_url(task)
  end
end
