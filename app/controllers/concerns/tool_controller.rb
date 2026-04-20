module ToolController
  extend ActiveSupport::Concern

  included do
    helper_method :user_max_file_size, :user_max_batch_size
  end

  private

  def user_max_file_size
    Upload.max_size_for(Current.user)
  end

  def user_max_batch_size
    Task.batch_limit_for(Current.user)
  end

  def create_task
    task = Task.create!(
      task_id: SecureRandom.uuid,
      tool: controller_name,
      ip_address: request.remote_ip
    )
    CleanupExpiredTasksJob.set(wait: 3.hours).perform_later(task.task_id)
    task
  end

  def find_task
    Task.find_by!(task_id: params[:task_id])
  end

  def render_download_url(task)
    render json: { download_url: download_path(task_id: task.task_id) }
  end
end
