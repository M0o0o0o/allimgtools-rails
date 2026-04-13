# frozen_string_literal: true

class AiPostGeneratorJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  FETCH_LIMIT = 5

  # goal: 글 목표 (예: "SEO가 궁금한 초보 블로거를 위한 글")
  def perform(goal:)
    Rails.logger.info "[AiPostGenerator] Starting for goal: #{goal}"
    openai = AiServices::OpenaiService.new

    # # Step 1: 검색어 생성
    # Rails.logger.info "[AiPostGenerator] Step 1: Generating search queries..."
    # search_queries = openai.generate_search_queries(goal: goal)
    # Rails.logger.info "[AiPostGenerator] Queries: #{search_queries.join(' / ')}"

    # # Step 2: Google 검색
    # Rails.logger.info "[AiPostGenerator] Step 2: Searching Google..."
    # google_results = Crawlers::GoogleSearch.new.search(query: search_queries.first, num: 10) || []

    # if google_results.empty?
    #   Rails.logger.error "[AiPostGenerator] No search results found"
    #   return
    # end

    # Rails.logger.info "[AiPostGenerator] Found #{google_results.size} results"

    # # Step 3: 크롤링
    # Rails.logger.info "[AiPostGenerator] Step 3: Fetching articles (limit: #{FETCH_LIMIT})..."
    # fetcher = Crawlers::ContentFetcher.new
    # articles = fetch_articles(fetcher, google_results, FETCH_LIMIT)

    # if articles.empty?
    #   Rails.logger.error "[AiPostGenerator] Failed to fetch any articles"
    #   return
    # end

    # Rails.logger.info "[AiPostGenerator] Fetched #{articles.size} articles"

    # # Step 4: 기사 분석 (병렬)
    # Rails.logger.info "[AiPostGenerator] Step 4: Analyzing articles..."
    # analyses = openai.analyze_articles(articles.map { |a| a[:content] }, goal: goal)

    # Step 5: 본문 → 메타 순서로 글 작성
    Rails.logger.info "[AiPostGenerator] Step 5: Generating post (body → meta)..."
    content = openai.generate_post(goal: goal, analyses: [])

    # 고유 slug 생성
    base_slug = content[:slug].presence || goal.parameterize
    slug = base_slug
    counter = 1
    while Post.exists?(slug: slug)
      slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    # 포스트 생성 (draft 상태)
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
