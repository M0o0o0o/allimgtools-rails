# frozen_string_literal: true

class TranslatePostJob < ApplicationJob
  queue_as :default

  SOURCE_LOCALE = "ko"

  def perform(post_id)
    post = Post.includes(:translations).find(post_id)
    source = post.translations.find { |t| t.locale == SOURCE_LOCALE }

    return unless source
    return if source.title.blank?

    target_locales = SUPPORTED_LOCALES.keys.map(&:to_s) - [ SOURCE_LOCALE ]

    target_locales.each do |locale|
      translation = post.translations.find { |t| t.locale == locale } ||
                    post.translations.build(locale: locale)

      translation.title       = translate(source.title, from: SOURCE_LOCALE, to: locale)
      translation.description = translate(source.description, from: SOURCE_LOCALE, to: locale) if source.description.present?
      translation.body        = translate_html(source.body.to_s, from: SOURCE_LOCALE, to: locale) if source.body.present?
      translation.save!
    end
  end

  private

  # TODO: AI API 연결 후 구현
  # @param text [String]
  # @param from [String] source locale (e.g. "ko")
  # @param to   [String] target locale (e.g. "en")
  # @return [String] translated text
  def translate(text, from:, to:)
    raise NotImplementedError, "translate() — AI API not connected yet"
  end

  # HTML rich text 번역 (태그 구조 유지)
  # TODO: AI API 연결 후 구현
  def translate_html(html, from:, to:)
    raise NotImplementedError, "translate_html() — AI API not connected yet"
  end
end
