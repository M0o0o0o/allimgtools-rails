class AddCtaToPostTranslations < ActiveRecord::Migration[8.1]
  def change
    add_column :post_translations, :cta_text, :string
    add_column :post_translations, :cta_url, :string
  end
end
