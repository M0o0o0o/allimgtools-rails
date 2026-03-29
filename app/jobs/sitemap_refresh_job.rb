# frozen_string_literal: true

class SitemapRefreshJob < ApplicationJob
  queue_as :default

  discard_on StandardError

  def perform
    FileUtils.mkdir_p(Rails.root.join("storage", "sitemaps"))
    load Rails.root.join("config", "sitemap.rb")
  end
end
