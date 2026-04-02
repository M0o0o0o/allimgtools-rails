# frozen_string_literal: true

class TranslatePostJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  SOURCE_LOCALE = "ko"
  TARGET_LOCALE = "en"

  def perform(post_id)
    post = Post.includes(:translations).find(post_id)
    source = post.translations.find { |t| t.locale == SOURCE_LOCALE }

    unless source
      Rails.logger.error "[TranslatePostJob] No Korean translation found for post #{post_id}"
      return
    end

    return if source.title.blank?

    Rails.logger.info "[TranslatePostJob] Translating post #{post_id} ko → en..."

    translated = AiServices::OpenaiService.new.translate_content(
      title: source.title,
      description: source.description,
      body: source.body.to_s,
      target_locale: TARGET_LOCALE
    )

    translation = post.translations.find { |t| t.locale == TARGET_LOCALE } ||
                  post.translations.build(locale: TARGET_LOCALE)
    translation.title       = translated[:title]
    translation.description = translated[:description]
    translation.body        = translated[:body] if source.body.present?
    translation.save!

    Rails.logger.info "[TranslatePostJob] Successfully translated post #{post_id} to en"
  end
end
