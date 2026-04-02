# frozen_string_literal: true

module Crawlers
  class ContentFetcher
    def fetch(url)
      browser = Ferrum::Browser.new(
        headless: true,
        process_timeout: 60,
        timeout: 60,
        browser_options: { "no-sandbox": nil, "disable-dev-shm-usage": nil }
      )

      browser.goto(url)
      sleep 2

      fetch_with_readability(browser, url)
    rescue Ferrum::Error => e
      Rails.logger.error "[ContentFetcher] Failed to fetch #{url}: #{e.message}"
      nil
    ensure
      browser&.quit
    end

    private

    def fetch_with_readability(browser, url)
      html = browser.body
      doc = Readability::Document.new(html)

      {
        url: url,
        title: doc.title,
        content: doc.content
      }
    end
  end
end
