class PostTranslation < ApplicationRecord
  belongs_to :post
  has_rich_text :body

  validates :locale, presence: true, inclusion: { in: -> (_) { SUPPORTED_LOCALES.keys.map(&:to_s) } }
  validates :locale, uniqueness: { scope: :post_id }
  validates :title, presence: true, unless: :blank_translation?

  def blank_translation?
    title.blank? && description.blank? && body.blank?
  end
end
