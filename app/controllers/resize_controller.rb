class ResizeController < ApplicationController
  include ToolController

  before_action :set_task, only: [ :show, :start ]

  def new
  end

  def show
    @uploads = @task.uploads.completed.with_attached_file
    @uploads.each { |u| u.file.blob.analyze unless u.file.analyzed? }
  end

  def start
    resizes = {}
    (params[:resizes] || {}).each do |upload_id, settings|
      resizes[upload_id] = {
        "width"                 => settings[:width].presence&.to_i,
        "height"                => settings[:height].presence&.to_i,
        "maintain_aspect_ratio" => settings[:maintain_aspect_ratio] == "1"
      }
    end

    @task.update!(status: "processing")
    ResizeImagesJob.perform_later(@task.task_id, resizes: resizes)

    redirect_to download_path(task_id: @task.task_id)
  end

  private

  def set_task
    @task = Task.find_by!(task_id: params[:task_id])
  end
end
