# frozen_string_literal: true

module AiServices
  class OpenaiService
    ANALYSIS_SYSTEM_PROMPT = <<~PROMPT
      You are a researcher collecting information to help write a helpful Korean blog post.

      Read the given article and pull out everything that could be useful — facts, tips, specific data,
      examples, common mistakes, surprising details, platform specs, anything a reader would find valuable.

      If previous research is provided:
      - Keep ALL existing facts as-is
      - Add every new piece of useful information from this article
      - Only skip something if it says exactly the same thing as an existing fact
      - When in doubt, keep it — more information is better than less
      - Update the summary to naturally reflect everything collected so far
    PROMPT

    WRITER_SYSTEM_PROMPT = <<~PROMPT
      You write Korean blog posts that are genuinely useful to readers — the kind of post that answers
      their question thoroughly and makes them feel like they learned something.

      ## Voice
      - Write in Korean, casual but knowledgeable — like a friend who actually knows this stuff
      - Be direct. Say exactly what you mean without warming up
      - Have opinions. "솔직히 이 방법이 제일 낫습니다" is better than "여러 방법이 있습니다"
      - Write like a human with their own rhythm — vary sentence length, mix short punchy lines with longer ones
      - It's fine to be a little conversational: "근데", "사실", "진짜로", "생각보다"

      ## Structure
      - Use HTML tags: h2, h3, p, ul, li, strong
      - 1000-1800 words
      - No h1 in body (title is separate)
      - Don't start by restating the title or announcing what the post will cover
      - Don't end with a summary section that just repeats everything
      - Structure should feel natural to the topic, not templated — sometimes a list makes sense, sometimes flowing paragraphs do

      ## What makes it sound like a human wrote it
      - Never use: "이러한", "따라서", "결과적으로", "그러므로", "즉,", "요약하자면", "살펴보겠습니다", "알아보겠습니다"
      - Don't number your sections or points ("1. 첫째", "2. 둘째")
      - Don't over-hedge with "일반적으로", "대부분의 경우", "보통은"
      - Avoid announcing what you're about to say — just say it
      - Don't balance every argument. Take a position
      - Skip the obvious. Readers already know the basics; get to the useful part

      ## Hard rules
      - Only use facts from the research — don't invent numbers or specs
      - No clichés: "완벽한 가이드", "모든 것", "숨겨진 팁", "쉽게 알아보는"

      ## Slug
      - Generate a URL slug in English: lowercase, hyphenated, SEO-friendly (e.g. "instagram-image-size-2026")
      - Max 60 characters, no special characters
    PROMPT

    TRANSLATION_PROMPT = <<~PROMPT
      Translate the following Korean blog post into the target language.

      Rules:
      - Keep the same casual, human tone as the original — do not make it more formal or structured
      - Translate naturally, not literally. If a Korean expression doesn't work in the target language, find an equivalent
      - Keep all HTML tags exactly as-is
      - Do not add or remove content
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
        ## 주제
        #{topic}

        ## 수집된 정보
        #{analysis[:facts].map { |f| "- #{f}" }.join("\n")}

        ## 전체 요약
        #{analysis[:summary]}

        위 정보를 바탕으로 블로그 글을 작성해주세요.
      MSG

      response = @client.chat(
        parameters: {
          model: "gpt-4o",
          temperature: 1.0,
          messages: [
            { role: "system", content: WRITER_SYSTEM_PROMPT },
            { role: "user", content: user_message }
          ],
          response_format: {
            type: "json_schema",
            json_schema: {
              name: "post",
              strict: true,
              schema: {
                type: "object",
                properties: {
                  slug:        { type: "string" },
                  title:       { type: "string" },
                  description: { type: "string" },
                  body:        { type: "string" }
                },
                required: [ "slug", "title", "description", "body" ],
                additionalProperties: false
              }
            }
          }
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
          response_format: {
            type: "json_schema",
            json_schema: {
              name: "translation",
              strict: true,
              schema: {
                type: "object",
                properties: {
                  title:       { type: "string" },
                  description: { type: "string" },
                  body:        { type: "string" }
                },
                required: [ "title", "description", "body" ],
                additionalProperties: false
              }
            }
          }
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
          response_format: {
            type: "json_schema",
            json_schema: {
              name: "analysis",
              strict: true,
              schema: {
                type: "object",
                properties: {
                  facts:   { type: "array", items: { type: "string" } },
                  summary: { type: "string" }
                },
                required: [ "facts", "summary" ],
                additionalProperties: false
              }
            }
          }
        }
      )

      response_text = response.dig("choices", 0, "message", "content")
      parse_analysis(response_text)
    end

    def build_analysis_prompt(article_text, previous_analysis)
      prompt = +"#{ANALYSIS_SYSTEM_PROMPT}\n\n"
      if previous_analysis
        prompt << "## Research So Far\n"
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
        facts: parsed["facts"] || [],
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
      { slug: parsed["slug"].presence, title: title, description: parsed["description"].presence, body: body }
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
