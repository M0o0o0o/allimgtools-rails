# frozen_string_literal: true

class TranslatePostJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  SOURCE_LOCALE = "ko"

  def perform(post_id, target_locale)
    post = Post.includes(:translations).find(post_id)
    source = post.translations.find { |t| t.locale == SOURCE_LOCALE }

    unless source
      Rails.logger.error "[TranslatePostJob] No Korean translation found for post #{post_id}"
      return
    end

    return if source.title.blank?

    Rails.logger.info "[TranslatePostJob] Translating post #{post_id} ko → #{target_locale}..."

    translated = AiServices::OpenaiService.new.translate_content(
      title: source.title,
      description: source.description,
      body: source.body.to_s,
      cta_text: source.cta_text,
      target_locale: target_locale
    )

    translation = post.translations.find { |t| t.locale == target_locale } ||
                  post.translations.build(locale: target_locale)
    translation.title       = translated[:title]
    translation.description = translated[:description]
    Rails.logger.warn "[TranslatePostJob] description is blank for post #{post_id} → #{target_locale}" if translated[:description].blank?
    translation.body        = translated[:body] if source.body.present?
    translation.cta_text    = translated[:cta_text] if source.cta_text.present?
    translation.cta_url     = source.cta_url
    translation.save!

    Rails.logger.info "[TranslatePostJob] Successfully translated post #{post_id} to #{target_locale}"
  end
end
