# frozen_string_literal: true

module Crawlers
  class GoogleSearch
    BASE_URL = "https://serpapi.com/search"

    def initialize
      @api_key = Rails.application.credentials.dig(:serpapi, :api_key)
    end

    def search(query:, gl: "us", hl: "en", num: 10)
      return nil unless num.between?(1, 100)

      response = fetch_results(query, gl, hl, num)
      return nil unless response
      parse_results(response)
    rescue StandardError => e
      Rails.logger.error "[GoogleSearch] Failed to search '#{query}': #{e.message}"
      nil
    end

    private

    def fetch_results(query, gl, hl, num)
      uri = URI(BASE_URL)
      uri.query = URI.encode_www_form(
        api_key: @api_key,
        engine: "google",
        q: query,
        gl: gl,
        hl: hl,
        num: num
      )

      request = Net::HTTP::Get.new(uri)

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error "[GoogleSearch] HTTP #{response.code}: #{response.body}"
        return nil
      end

      JSON.parse(response.body)
    end

    def parse_results(data)
      items = data["organic_results"] || []

      items.map do |item|
        {
          title: item["title"],
          link: item["link"],
          excerpt: item["snippet"]
        }
      end
    end
  end
end
