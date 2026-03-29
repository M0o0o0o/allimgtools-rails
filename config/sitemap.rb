# frozen_string_literal: true

SitemapGenerator::Sitemap.default_host = "https://allimgtools.com"
SitemapGenerator::Sitemap.compress = true
SitemapGenerator::Sitemap.public_path = Rails.root.join("storage", "sitemaps").to_s + "/"

SitemapGenerator::Sitemap.create(include_root: false) do
  locales = SUPPORTED_LOCALES.keys

  # Build alternates array for hreflang
  build_alternates = ->(path_builder) {
    locales.map do |locale|
      {
        href: "#{SitemapGenerator::Sitemap.default_host}#{path_builder.call(locale)}",
        lang: locale.to_s
      }
    end
  }

  # Locale-prefixed path (no prefix for :en)
  locale_path = ->(locale, path = "") {
    locale == :en ? "/#{path}".chomp("/") : "/#{locale}/#{path}".chomp("/")
  }
  locale_path_or_root = ->(locale, path = "") {
    result = locale_path.call(locale, path)
    result.empty? ? "/" : result
  }

  # Static tool pages
  static_pages = [
    { path: "",            priority: 1.0, changefreq: "monthly" },
    { path: "compress",    priority: 0.9, changefreq: "monthly" },
    { path: "resize",      priority: 0.9, changefreq: "monthly" },
    { path: "convert",     priority: 0.9, changefreq: "monthly" },
    { path: "exif",        priority: 0.9, changefreq: "monthly" },
    { path: "rotate",      priority: 0.9, changefreq: "monthly" },
    { path: "jpg-to-png",  priority: 0.8, changefreq: "monthly" },
    { path: "jpg-to-webp", priority: 0.8, changefreq: "monthly" },
    { path: "png-to-jpg",  priority: 0.8, changefreq: "monthly" },
    { path: "png-to-webp", priority: 0.8, changefreq: "monthly" },
    { path: "webp-to-jpg", priority: 0.8, changefreq: "monthly" },
    { path: "webp-to-png", priority: 0.8, changefreq: "monthly" }
  ]

  static_pages.each do |page|
    page_alternates = build_alternates.call(->(l) {
      page[:path].empty? ? locale_path_or_root.call(l) : locale_path.call(l, page[:path])
    })

    locales.each do |locale|
      url = page[:path].empty? ? locale_path_or_root.call(locale) : locale_path.call(locale, page[:path])
      add url,
          changefreq: page[:changefreq],
          priority: page[:priority],
          alternates: page_alternates
    end
  end

  # Blog posts will be added here later
  # Post.published.includes(:translations).find_each do |post| ... end
end
