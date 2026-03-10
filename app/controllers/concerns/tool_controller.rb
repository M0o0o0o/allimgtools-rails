module ToolController
  extend ActiveSupport::Concern

  included do
    before_action :ensure_task, only: [ :new ]
  end

  private

  def ensure_task
    if params[:task_id].present?
      @task = Task.find_by(task_id: params[:task_id])
      redirect_to send(:"new_#{controller_name}_path") if @task.nil?
    else
      @task = Task.create!(
        task_id: SecureRandom.uuid,
        tool: controller_name,
        ip_address: request.remote_ip
      )
      CleanupExpiredTasksJob.set(wait: 3.hours).perform_later(@task.task_id)
      redirect_to url_for(action: :new, task_id: @task.task_id)
    end
  end
end
