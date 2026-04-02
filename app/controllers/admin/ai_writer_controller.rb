# frozen_string_literal: true

module Admin
  class AiWriterController < BaseController
    def index
    end

    def generate
      topics = params[:topics]&.values || []

      if topics.empty?
        redirect_to admin_ai_writer_path, alert: "주제를 입력해주세요."
        return
      end

      topics.each do |topic_data|
        AiPostGeneratorJob.perform_later(
          topic: topic_data[:topic],
          search_query: topic_data[:search_query]
        )
      end

      redirect_to admin_posts_path, notice: "#{topics.size}개의 글 생성이 시작됐습니다. 잠시 후 Posts 목록에서 확인하세요."
    end
  end
end
