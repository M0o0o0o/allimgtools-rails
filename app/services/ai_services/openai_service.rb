# frozen_string_literal: true

module AiServices
  class OpenaiService
    ANALYSIS_SYSTEM_PROMPT = <<~PROMPT
      You are a content researcher specializing in image processing, web optimization, and digital media topics.
      Analyze the given article and extract useful information for writing an image tools blog post.

      ## Analysis Principles
      - Extract key ideas, tips, techniques, and facts about image processing/optimization
      - Focus on practical information useful for web developers, designers, and general users
      - If previous analysis is provided, integrate new information into it
      - Remove duplicates; preserve both sides of conflicting information
      - Keep specific details (tools, formats, file sizes, performance numbers)

      ## Response Format
      Respond ONLY in valid JSON:
      {
        "key_ideas": ["main ideas for a blog post"],
        "useful_info": ["practical tips, specific details (tools, sizes, formats)"],
        "statistics_and_facts": ["numbers, benchmarks, format comparisons"],
        "unique_insights": ["non-obvious insights or lesser-known tips"],
        "content_angles": ["suggested sections or angles for the article"],
        "summary": "overall summary of findings"
      }
    PROMPT

    WRITER_SYSTEM_PROMPT = <<~PROMPT
      You write blog posts about image processing and optimization for web developers, designers, and general users.
      Write like a knowledgeable friend sharing what they actually know, not a technical manual.

      ## Voice & Tone
      - Write in Korean
      - Be direct and specific. Say "WebP는 JPG보다 평균 30% 작아요" instead of "WebP can reduce file sizes"
      - Share practical details only someone experienced would know
      - It's okay to have opinions. "솔직히 PNG to WebP 변환이 가장 효과적인 방법이에요"
      - Skip generic intro paragraphs. Get to useful content fast
      - Mix paragraphs and lists naturally — don't overuse bullet points
      - Never use filler phrases like "이 포괄적인 가이드에서", "함께 알아보겠습니다", "모든 것을 알아보세요"

      ## Structure
      - Use HTML tags: h2, h3, p, ul, li, strong
      - 1000-1800 words
      - No h1 tag in body (title is separate)
      - Start body directly with content, not a repeat of the title

      ## What NOT to do
      - Don't make up specific facts or numbers not in the analysis
      - Don't write a "conclusion" section that just repeats everything
      - Don't use cliché phrases ("완벽한 가이드", "최고의 방법", "숨겨진 팁")
      - Don't number your sections ("1. 첫 번째", "2. 두 번째")

      ## Response Format
      Return ONLY a JSON object:
      {
        "title": "Short, natural Korean title (under 60 chars)",
        "description": "Meta description in Korean (under 155 chars)",
        "body": "HTML body content"
      }
    PROMPT

    def initialize
      @client = OpenAI::Client.new(
        access_token: Rails.application.credentials.dig(:openai, :api_key)
      )
    end

    def analyze_articles(articles)
      analysis = nil
      articles.each_with_index do |article, index|
        Rails.logger.info "[OpenaiService] Analyzing article #{index + 1}/#{articles.size}..."
        analysis = analyze_article(article, previous_analysis: analysis)
      end
      analysis
    end

    def generate_post(topic:, analysis:)
      user_message = <<~MSG
        ## Topic
        #{topic}

        ## Research Analysis
        #{JSON.pretty_generate(analysis)}

        위 분석 자료를 활용하여 블로그 글을 작성해주세요.
      MSG

      response = @client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: WRITER_SYSTEM_PROMPT },
            { role: "user", content: user_message }
          ],
          response_format: { type: "json_object" }
        }
      )

      response_text = response.dig("choices", 0, "message", "content")
      parse_post(response_text)
    end

    def translate_content(title:, description:, body:, target_locale:)
      locale_name = SUPPORTED_LOCALES[target_locale.to_sym]&.dig(:name) || target_locale.to_s.upcase
      prompt = +"#{TRANSLATION_PROMPT}\n\n"
      prompt << "## Target Language: #{locale_name}\nYou MUST write ALL output in #{locale_name}.\n\n"
      prompt << "## Content to Translate\n"
      prompt << "Title: #{title}\n"
      prompt << "Description: #{description}\n"
      prompt << "Body:\n#{body}\n"

      response = @client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            { role: "user", content: prompt }
          ],
          response_format: { type: "json_object" }
        }
      )

      response_text = response.dig("choices", 0, "message", "content")
      parse_translation(response_text)
    end

    private

    def analyze_article(article_text, previous_analysis: nil)
      user_prompt = build_analysis_prompt(article_text, previous_analysis)

      response = @client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            { role: "user", content: user_prompt }
          ],
          response_format: { type: "json_object" }
        }
      )

      response_text = response.dig("choices", 0, "message", "content")
      parse_analysis(response_text)
    end

    def build_analysis_prompt(article_text, previous_analysis)
      prompt = +"#{ANALYSIS_SYSTEM_PROMPT}\n\n"
      if previous_analysis
        prompt << "## Previous Analysis (integrate new info into this)\n"
        prompt << previous_analysis.to_json
        prompt << "\n\n"
      end
      prompt << "## Article to Analyze\n"
      prompt << article_text.to_s
      prompt
    end

    def parse_analysis(response_text)
      parsed = JSON.parse(response_text)
      {
        key_ideas: parsed["key_ideas"] || [],
        useful_info: parsed["useful_info"] || [],
        statistics_and_facts: parsed["statistics_and_facts"] || [],
        unique_insights: parsed["unique_insights"] || [],
        content_angles: parsed["content_angles"] || [],
        summary: parsed["summary"] || ""
      }
    rescue JSON::ParserError => e
      Rails.logger.error "[OpenaiService] Failed to parse analysis: #{e.message}"
      raise "Failed to parse AI analysis response"
    end

    def parse_post(response_text)
      parsed = JSON.parse(response_text)
      title = parsed["title"].presence
      body  = parsed["body"].presence
      raise "Failed to parse AI response: missing title or body" if title.nil? || body.nil?
      { title: title, description: parsed["description"].presence, body: body }
    rescue JSON::ParserError => e
      Rails.logger.error "[OpenaiService] Failed to parse post: #{e.message}"
      raise "Failed to parse AI post response"
    end

    def parse_translation(response_text)
      parsed = JSON.parse(response_text)
      { title: parsed["title"], description: parsed["description"], body: parsed["body"] }
    rescue JSON::ParserError => e
      Rails.logger.error "[OpenaiService] Failed to parse translation: #{e.message}"
      raise "Failed to parse AI translation response"
    end
  end
end
