# frozen_string_literal: true

class AiPostGeneratorJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  FETCH_LIMIT = 5

  # topic:        한국어 주제 (글 작성용)
  # search_query: 영어 검색어 (Google 검색용)
  def perform(topic:, search_query:)
    Rails.logger.info "[AiPostGenerator] Starting for topic: #{topic}, query: #{search_query}"

    # Step 1: Google 검색
    Rails.logger.info "[AiPostGenerator] Step 1: Searching Google..."
    google_results = Crawlers::GoogleSearch.new.search(query: search_query, num: 10) || []

    if google_results.empty?
      Rails.logger.error "[AiPostGenerator] No search results found"
      return
    end

    Rails.logger.info "[AiPostGenerator] Found #{google_results.size} results"

    # Step 2: 크롤링
    Rails.logger.info "[AiPostGenerator] Step 2: Fetching articles (limit: #{FETCH_LIMIT})..."
    fetcher = Crawlers::ContentFetcher.new
    articles = fetch_articles(fetcher, google_results, FETCH_LIMIT)

    if articles.empty?
      Rails.logger.error "[AiPostGenerator] Failed to fetch any articles"
      return
    end

    Rails.logger.info "[AiPostGenerator] Fetched #{articles.size} articles"

    # Step 3: GPT-4o-mini로 분석
    Rails.logger.info "[AiPostGenerator] Step 3: Analyzing articles with GPT-4o-mini..."
    openai = AiServices::OpenaiService.new
    analysis = openai.analyze_articles(articles.map { |a| a[:content] })

    # Step 4: GPT-4o-mini로 글 작성
    Rails.logger.info "[AiPostGenerator] Step 4: Generating post with GPT-4o-mini..."
    content = openai.generate_post(topic: topic, analysis: analysis)

    # 고유 slug 생성
    base_slug = content[:title].parameterize.presence || topic.parameterize
    slug = base_slug
    counter = 1
    while Post.exists?(slug: slug)
      slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    # 포스트 생성 (draft 상태) — 한국어로 저장 후 영어 번역 job 큐잉
    post = Post.create!(slug: slug, status: :draft)
    post.translations.create!(
      locale: "ko",
      title: content[:title],
      description: content[:description],
      body: content[:body]
    )

    TranslatePostJob.perform_later(post.id)

    Rails.logger.info "[AiPostGenerator] Successfully created post: #{post.slug} (id: #{post.id}), translation queued"
  end

  private

  def fetch_articles(fetcher, results, limit)
    articles = []
    results.each do |result|
      break if articles.size >= limit
      article = fetcher.fetch(result[:link])
      articles << article if article
    end
    articles
  end
end
