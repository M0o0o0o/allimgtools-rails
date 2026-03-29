# frozen_string_literal: true

class SitemapsController < ApplicationController
  def show
    sitemap_path = Rails.root.join("storage", "sitemaps", "sitemap.xml.gz")

    if File.exist?(sitemap_path)
      response.headers["Content-Encoding"] = "gzip"
      send_file sitemap_path, type: "application/xml", disposition: "inline"
    else
      render plain: "Sitemap not generated yet", status: :not_found
    end
  end
end
