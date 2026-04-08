# frozen_string_literal: true

module Admin
  class AiWriterController < BaseController
    def index
    end

    def generate
      goals = params[:goals]&.values || []

      if goals.empty?
        redirect_to admin_ai_writer_path, alert: "글 목표를 입력해주세요."
        return
      end

      goals.each do |goal|
        AiPostGeneratorJob.perform_later(goal: goal)
      end

      redirect_to admin_posts_path, notice: "#{goals.size}개의 글 생성이 시작됐습니다. 잠시 후 Posts 목록에서 확인하세요."
    end
  end
end
