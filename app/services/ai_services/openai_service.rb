# frozen_string_literal: true

module AiServices
  class OpenaiService
    SEARCH_QUERY_PROMPT = <<~PROMPT
      You are an SEO content researcher.
      Given a Korean blog post goal, generate 3 English Google search queries to find the best reference articles.
      Queries should be natural English search phrases — the kind a real person would type into Google.
    PROMPT

    ANALYSIS_SYSTEM_PROMPT = <<~PROMPT
      You are a research assistant extracting material for a Korean blog post.

      ## Goal
      The blog post goal tells you who the reader is and what they need.
      Extract only information that is useful for that specific reader.
      Skip content that's too advanced, too basic, or irrelevant to the goal.

      ## What to extract
      Concrete facts, numbers, named tools, methods, real examples, common mistakes, counterintuitive findings.
      Write in loose bullet points. Restate in your own words — never copy sentences verbatim.
      Skip vague claims with no substance ("X is very important", "Y is essential").
    PROMPT

    META_SYSTEM_PROMPT = <<~PROMPT
      주어진 블로그 글 목표와 작성된 본문을 바탕으로 메타 정보를 생성하세요.

      ## 제목 (title)
      독자가 스크롤을 멈추게 만드는 제목이어야 합니다.
      구체적인 수치, 반직관적 주장, 또는 독자의 상황을 정확히 짚는 표현을 써야 합니다.

      금지:
      - "X 이해하기", "X 알아보기", "X의 중요성", "완벽한 X 가이드", "X란 무엇인가"
      - 콜론으로 앞뒤 나눈 제목 ("X: Y와 Z 방법")
      - "— X가 필요한 이유" 같은 접미사 패턴

      40자 이내

      ## 설명 (description)
      독자가 "이거 나한테 딱 필요한 글이네"라고 느끼게 만드세요.
      독자가 겪는 구체적인 상황을 짚고, 이 글이 거기에 어떻게 답하는지 말하세요.
      "X의 개념과 중요성을 이해하고 Y 방법을 제공합니다" 패턴은 금지입니다.
      80~120자

      ## 슬러그 (slug)
      영어, 소문자, 하이픈 구분. 핵심 키워드 2~3개. 최대 60자.
    PROMPT

    BODY_SYSTEM_PROMPT = <<~PROMPT
  당신은 직접 부딪혀가며 배운 것들을 쉽게 풀어쓰는 작가입니다.
  교과서 설명이 아니라, 독자가 실제로 겪는 상황에서 말하듯 씁니다.

  ## 출력 형식
  반드시 HTML만 출력하세요. 첫 글자는 반드시 "<"이어야 합니다.
  사용 태그: h2, h3, p, ul, li, strong
  금지: 마크다운, 코드블록, h1

  ## 독자
  글 목표에 명시된 독자를 기준으로 씁니다.

  ## 어투
  - "~예요", "~거든요", "~인 거죠" 체로 써라
  - "~합니다", "~입니다" 체는 금지
  - 구어체 적극 사용: "근데", "사실", "진짜로", "생각보다", "그러니까"

  ## 결론을 먼저
  설명하고 결론 내리지 말고, 결론 던지고 이유 붙여라.
  나쁜 예: "광고는 비용이 소모되지만 SEO는 지속적입니다."
  좋은 예: "광고는 돈 끊으면 바로 꺼져요. SEO는 달라요."

  ## 자료 활용
  수집된 자료에 구체적인 숫자, 사례, 도구명이 있으면 반드시 써라.
  숫자는 의미까지 해석해라. 숫자만 던지지 마라.
  익명 사례 금지: "많은 기업들이 성과를 거뒀습니다."

  ## 구성
  - 반드시 10개 이상의 소제목(h2) 섹션으로 구성 (전체 세션이 자연스럽게 이어져야 함)
  - 각 섹션 최소 3문단
  - 문단당 최소 4문장 이상
  - 단, 섹션 2~3개는 의도적으로 짧게 (1~2문단) — 리듬 변주용
  - 글의 시작은 해당 독자가 관심을 갖고 계속 글을 읽을 수 있게 시작
  - 마지막 섹션은 반드시 글의 핵심 주제 안에서 닫아라. 독자에게 한마디 던지거나 필자의 한 줄 소감으로 마무리해도 좋다

  ## 필자의 목소리 (필수)
  - 최소 2곳에서 필자의 판단을 직접 밝혀라. 중립적 설명으로만 채우면 안 된다
    반드시 포함: "저는 ~라고 생각해요", "솔직히 ~", "개인적으로는 ~"
  - 독자가 흔히 오해하는 지점을 1곳에서 직접 짚어라

  ## 예시 연결
  - "예를 들어"는 글 전체에서 최대 3회. 초과하면 안 됨
  - 대신: "실제로 ~보면", "~라고 생각하면 돼요", 또는 접속사 없이 바로 사례로 시작

  ## 절대 금지 표현
  "이러한", "이처럼", "이를 통해", "따라서", "결과적으로", "즉,", "요약하자면", "결국"
  "살펴보겠습니다", "알아보겠습니다", "~에 대해 이야기해보겠습니다"
  "첫째", "둘째", "셋째", "첫 번째로", "두 번째로"
  "~하는 것이 중요합니다", "~의 중요성은 아무리 강조해도"
  "여러분", "걱정 마세요", "쉽게 따라할 수 있습니다"
  "그리고", "또한", "또"으로만 문단 시작
  "~뿐만 아니라", "더불어", "아울러"
PROMPT

    TRANSLATION_PROMPT = <<~PROMPT
      Translate the following Korean blog post into the target language.

  ## Translation approach
  Translate meaning, not words.
  Ask: "How would a native speaker naturally say this?"
  — not "What does each word mean?"
  Never translate word-for-word. If a sentence sounds
  like a translation, rewrite it until it doesn't.

  ## Title & description
  These are the first things a reader sees.
  They must feel like they were written in the target
  language from the start — not translated.
  Rewrite them as a native speaker would write them,
  while keeping the original meaning and tone.
  It's okay if the wording changes significantly.

  ## Tone
  The original is casual, direct, and written like
  someone talking to a friend.
  Do not make it more formal, more structured, or more
  "professional" in translation.
  If the original is blunt, stay blunt.
  If it's dry, stay dry.

  ## Sentence rhythm
  The original uses short sentences deliberately —
  often for emphasis.
  Preserve that rhythm. Do not merge short sentences
  into longer ones to sound more "natural."
  A one-line paragraph in the original stays
  a one-line paragraph.

  ## Korean expressions
  Some Korean expressions don't translate literally.
  Find a natural equivalent in the target language.
  Do not transliterate or leave Korean phrasing
  patterns in the output.

  ## HTML
  Keep all HTML tags exactly as-is.
  Translate only the text content inside them.

  ## Strict rules
  - Do not add content that isn't in the original
  - Do not remove content from the original
  - Do not add transitional phrases or summaries
    that weren't there
  - Do not smooth over abrupt tone shifts
    — they're intentional

  ## Before outputting
  Read your translation mentally.
  If any sentence feels like a translation — rewrite it.
  The final output should feel like it was originally
  written in the target language.
    PROMPT

    def initialize
      @client = OpenAI::Client.new(
        access_token: Rails.application.credentials.dig(:openai, :api_key)
      )
    end

    def generate_search_queries(goal:)
      response = @client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: SEARCH_QUERY_PROMPT },
            { role: "user", content: "Blog post goal: #{goal}" }
          ],
          response_format: {
            type: "json_schema",
            json_schema: {
              name: "search_queries",
              strict: true,
              schema: {
                type: "object",
                properties: {
                  queries: { type: "array", items: { type: "string" } }
                },
                required: [ "queries" ],
                additionalProperties: false
              }
            }
          }
        }
      )
      parsed = JSON.parse(response.dig("choices", 0, "message", "content"))
      parsed["queries"]
    end

    def analyze_articles(articles, goal:)
      futures = articles.each_with_index.map do |article, index|
        Concurrent::Future.execute do
          Rails.logger.info "[OpenaiService] Analyzing article #{index + 1}/#{articles.size}..."
          analyze_article(article, goal: goal)
        end
      end
      futures.map(&:value!)
    end

    def generate_post(goal:, analyses:)
      notes_text = analyses.each_with_index.map { |a, i| "### 자료 #{i + 1}\n#{a[:notes]}" }.join("\n\n")

      # Step 1: body
      Rails.logger.info "[OpenaiService] Step 1: Generating body..."
      body = generate_body(goal: goal, notes_text: notes_text)

      # Step 2: meta (본문 기반)
      Rails.logger.info "[OpenaiService] Step 2: Generating meta..."
      meta = generate_meta(goal: goal, body: body)

      meta.merge(body: body)
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

    def generate_body(goal:, notes_text:)
      user_message = <<~MSG
        ## 글 목표
        #{goal}

        ## 수집된 자료
        #{notes_text}

        위 자료를 활용해서 글 목표에 맞는 블로그 본문을 작성해주세요.
      MSG

      response = @client.chat(
        parameters: {
          model: "gpt-4o",
          temperature: 0.7,
          max_tokens: 12000,
          messages: [
            { role: "system", content: BODY_SYSTEM_PROMPT },
            { role: "user", content: user_message }
          ]
        }
      )

      response.dig("choices", 0, "message", "content").to_s.strip
    end

    def generate_meta(goal:, body:)
      user_message = <<~MSG
        ## 글 목표
        #{goal}

        ## 작성된 본문
        #{body}
      MSG

      response = @client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: META_SYSTEM_PROMPT },
            { role: "user", content: user_message }
          ],
          response_format: {
            type: "json_schema",
            json_schema: {
              name: "meta",
              strict: true,
              schema: {
                type: "object",
                properties: {
                  slug:        { type: "string" },
                  title:       { type: "string" },
                  description: { type: "string" }
                },
                required: [ "slug", "title", "description" ],
                additionalProperties: false
              }
            }
          }
        }
      )

      response_text = response.dig("choices", 0, "message", "content")
      parse_meta(response_text)
    end

    def analyze_article(article_text, goal:)
      response = @client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: ANALYSIS_SYSTEM_PROMPT },
            { role: "user", content: "## Blog Post Goal\n#{goal}\n\n## Article to Analyze\n#{article_text}" }
          ],
          response_format: {
            type: "json_schema",
            json_schema: {
              name: "analysis",
              strict: true,
              schema: {
                type: "object",
                properties: {
                  notes: { type: "string" }
                },
                required: [ "notes" ],
                additionalProperties: false
              }
            }
          }
        }
      )

      response_text = response.dig("choices", 0, "message", "content")
      parse_analysis(response_text)
    end

    def parse_meta(response_text)
      parsed = JSON.parse(response_text)
      title = parsed["title"].presence
      raise "Failed to parse AI meta response: missing title" if title.nil?
      { slug: parsed["slug"].presence, title: title, description: parsed["description"].presence }
    rescue JSON::ParserError => e
      Rails.logger.error "[OpenaiService] Failed to parse meta: #{e.message}"
      raise "Failed to parse AI meta response"
    end

    def parse_analysis(response_text)
      parsed = JSON.parse(response_text)
      { notes: parsed["notes"] || "" }
    rescue JSON::ParserError => e
      Rails.logger.error "[OpenaiService] Failed to parse analysis: #{e.message}"
      raise "Failed to parse AI analysis response"
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
