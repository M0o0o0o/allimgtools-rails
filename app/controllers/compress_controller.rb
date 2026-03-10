class CompressController < ApplicationController
  include ToolController

  before_action :set_task, only: [ :show, :start ]

  def new
  end

  def show
    @uploads = @task.uploads.completed.with_attached_file
  end

  def start
    quality = params[:quality].to_i.clamp(1, 100)

    @task.update!(status: "processing")
    CompressImagesJob.perform_later(@task.task_id, quality: quality)

    redirect_to download_path(task_id: @task.task_id)
  end

  private

  def set_task
    @task = Task.find_by!(task_id: params[:task_id])
  end
end
