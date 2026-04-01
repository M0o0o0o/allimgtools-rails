class Post < ApplicationRecord
  has_many :translations, class_name: "PostTranslation", dependent: :destroy
  accepts_nested_attributes_for :translations, allow_destroy: true,
    reject_if: ->(attrs) { attrs[:title].blank? && attrs[:description].blank? && attrs[:body].blank? }

  enum :status, { draft: 0, published: 1, archived: 2 }

  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
  validates :status, presence: true

  scope :with_locale, ->(locale) {
    joins(:translations).where(post_translations: { locale: locale.to_s })
  }

  scope :published_ordered, -> { published.order(published_at: :desc) }

  def translation_for(locale)
    translations.find_by(locale: locale.to_s) ||
      translations.find_by(locale: I18n.default_locale.to_s)
  end

  def build_missing_translations
    existing_locales = translations.map(&:locale)
    SUPPORTED_LOCALES.keys.each do |locale|
      translations.build(locale: locale.to_s) unless existing_locales.include?(locale.to_s)
    end
  end
end
