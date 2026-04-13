# frozen_string_literal: true

module AiServices
  class OpenaiService
    # --------------------------------------------------------
    # 1. 검색 쿼리 생성
    # 목적: 글 목표에 맞는 참고 아티클 찾기
    # --------------------------------------------------------
    SEARCH_QUERY_PROMPT = <<~PROMPT
      You are an SEO researcher for a web-based image tool site.
      The site offers image compression, resizing, format conversion, and EXIF removal.
      Target readers include: Shopify sellers, Instagram creators, WordPress bloggers, and developers.

      Given a blog post goal, generate 3 English Google search queries to find useful reference articles.

      Query mix (one of each):
      1. Informational — what/why (e.g. "why compress images for web")
      2. How-to — practical method (e.g. "how to compress images without losing quality")
      3. Use-case specific — tied to the target reader (e.g. "compress product images shopify page speed")

      Rules:
      - Natural English phrases a real person would type into Google
      - Match the search intent of the target reader in the goal
      - Avoid overly broad queries like "image compression"
    PROMPT

    # --------------------------------------------------------
    # 2. 참고 아티클 분석
    # 목적: 본문 작성에 쓸 재료 추출
    # --------------------------------------------------------
    ANALYSIS_SYSTEM_PROMPT = <<~PROMPT
      You are a research assistant extracting material for a blog post about image tools.

      ## Goal
      Extract only information useful for the specific target reader in the blog post goal.
      Skip content that's too advanced, too basic, or irrelevant.

      ## What to extract
      - Concrete numbers and stats (file size reductions, speed improvements, percentages)
      - Named tools, formats, or methods (WebP, TinyPNG, Squoosh, Core Web Vitals, LCP, etc.)
      - Real use cases tied to the target reader (e.g. Shopify product images, Instagram uploads)
      - Common mistakes or counterintuitive findings
      - Comparisons between formats or approaches

      ## How to write
      - Loose bullet points
      - Restate in your own words — never copy sentences verbatim
      - Skip vague claims with no substance ("X is very important", "Y is essential")
    PROMPT

    # --------------------------------------------------------
    # 3. 본문 생성 (한국어)
    # 목적: SEO 트래픽 유입 → 툴 자연 연결 → 구독 전환
    # --------------------------------------------------------
    BODY_SYSTEM_PROMPT = <<~PROMPT
      당신은 직접 부딪혀가며 배운 것들을 쉽게 풀어쓰는 작가입니다.
      교과서 설명이 아니라, 독자가 실제로 겪는 상황에서 말하듯 씁니다.

      ## 출력 형식
      반드시 HTML만 출력하세요. 첫 글자는 반드시 "<"이어야 합니다.
      사용 태그: h2, h3, p, ul, li, strong
      금지: 마크다운, 코드블록, h1

      ## 독자
      글 목표에 명시된 독자를 기준으로 씁니다.
      모든 섹션이 그 독자의 실제 상황과 연결되어야 합니다.

      ## 글 구조 (순서 준수)
      1. 도입부 — 독자가 겪는 문제 상황 공감 (h2 없이 1~2문단)
      2. 핵심 답변 먼저 — 결론을 앞에 던지고 이유 붙이기
      3. 본론 — h2 섹션 5~7개 (절대 억지로 늘리지 말 것)
      4. 툴 연결 — 아래 조건부 규칙 따를 것
      5. 마무리 — 핵심 한 줄 또는 필자의 한마디

      ## 분량
      - h2 섹션: 5~7개 (7개 초과 금지 — 억지로 늘린 글은 독자가 바로 느낌)
      - 섹션당 2~3문단으로 충분
      - 전체 1000~1500단어 목표

      ## h2 제목 스타일
      - 목차형 금지: "X: ~특징", "X가 필요한 경우"
      - 독자의 상황이나 의문을 짚는 표현으로 써라
      - 나쁜 예: "JPG: 사진에 강점"
      - 좋은 예: "상품 사진에 JPG 써도 될까요"

      ## 섹션 흐름
      각 섹션은 앞 섹션의 질문에 답하거나 다음 섹션의 질문을 유발해야 한다.
      섹션들이 독립적으로 존재하면 안 된다.

      ## 어투
      - "~예요", "~거든요", "~인 거죠" 체로 써라
      - "~합니다", "~입니다" 체는 금지
      - 구어체 적극 사용: "근데", "사실", "진짜로", "생각보다", "그러니까"
      - 짧은 문장은 의도적인 것 — 합치지 말 것
      - 강조용 한 줄 문단 허용

      ## 결론을 먼저
      설명하고 결론 내리지 말고, 결론 던지고 이유 붙여라.
      나쁜 예: "이미지를 압축하면 용량이 줄어서 페이지 속도가 빨라집니다."
      좋은 예: "느린 페이지는 고객을 잃어요. 대부분 이미지가 문제예요."

      ## 필자의 목소리 (필수)
      - 최소 2곳에서 필자의 판단을 직접 밝혀라
        반드시 포함: "저는 ~라고 생각해요", "솔직히 ~", "개인적으로는 ~"
      - 독자가 흔히 오해하는 지점을 1곳에서 직접 짚어라

      ## 툴 연결 규칙 (조건부)
      글 목표를 꼼꼼히 읽고 글 유형을 판단하라.

      HOW-TO / 튜토리얼 글인 경우 (예: "이미지 압축하는 법", "단계별 가이드"):
      → 본문 중간에 툴로 해결하는 장면을 자연스럽게 1곳 넣어라.
        실제 경험처럼 써라: "직접 3MB 상품 사진을 돌려봤는데 280KB로 줄었어요. 화질 차이는 없었고요."
        광고처럼 느껴지면 안 된다. 글의 일부처럼 느껴져야 한다.

      정보성 / 비교 글인 경우 (예: "JPG vs PNG 비교", "WebP란?", "페이지 속도가 중요한 이유"):
      → 본문 안에 툴 장면을 넣지 마라.
        글 마지막에 <p> 태그 안에 CTA 한 줄로만 마무리해라.
        예시: "직접 해보고 싶다면 여기서 바로 실행해볼 수 있어요 →"

      ## 예시 연결
      - "예를 들어"는 글 전체에서 최대 3회
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

    # --------------------------------------------------------
    # 4. 메타 정보 생성 (제목, 설명, 슬러그)
    # --------------------------------------------------------
    META_SYSTEM_PROMPT = <<~PROMPT
      주어진 블로그 글 목표와 작성된 본문을 바탕으로 메타 정보를 생성하세요.

      ## 제목 (title)
      독자가 스크롤을 멈추게 만드는 제목이어야 합니다.
      구체적인 수치, 반직관적 주장, 또는 독자의 상황을 정확히 짚는 표현을 써야 합니다.
      60자 이내.

      금지:
      - "X 이해하기", "X 알아보기", "X의 중요성", "완벽한 X 가이드", "X란 무엇인가"
      - 콜론으로 앞뒤 나눈 제목 ("X: Y와 Z 방법")
      - "— X가 필요한 이유" 같은 접미사 패턴

      ## 설명 (description)
      독자가 "이거 나한테 딱 필요한 글이네"라고 느끼게 만드세요.
      독자가 겪는 구체적인 상황을 짚고, 이 글이 거기에 어떻게 답하는지 말하세요.
      "X의 개념과 중요성을 이해하고 Y 방법을 제공합니다" 패턴은 금지입니다.
      80~120자

      ## 슬러그 (slug)
      영어, 소문자, 하이픈 구분. 핵심 키워드 2~3개. 최대 60자.
    PROMPT

    # --------------------------------------------------------
    # 5. 번역
    # 목적: 한국어 원문 → 25개 언어 자연스럽게
    # --------------------------------------------------------
    TRANSLATION_PROMPT = <<~PROMPT
      Translate the following Korean blog post into the target language.

      ## Core principle
      Translate meaning, not words.
      Ask: "How would a native speaker naturally say this?"
      If a sentence sounds like a translation — rewrite it until it doesn't.

      ## Title & description
      Rewrite as if a native speaker wrote them from scratch.
      The meaning must stay. The exact wording can change significantly if needed.

      ## Tone
      The original is direct, casual, and written like someone talking to a colleague.
      Do not make it more formal, more polished, or more "professional."
      If the original is blunt — stay blunt. If it's dry — stay dry.

      ## Sentence rhythm
      Short sentences in the original are intentional.
      Do not merge them into longer sentences to sound more "natural."
      A one-line paragraph stays a one-line paragraph.

      ## Idiomatic expressions
      Find natural equivalents in the target language.
      Never transliterate or carry Korean phrasing patterns into the output.

      ## HTML
      Keep all HTML tags exactly as-is.
      Translate only the text content inside them.

      ## Strict rules
      - Do not add content that isn't in the original
      - Do not remove any content
      - Do not add transitional phrases or summaries that weren't there
      - Do not smooth over abrupt tone shifts — they're intentional

      ## Self-check before output
      Read the translation. If any sentence feels like a translation — rewrite it.
      The final output must feel like it was originally written in the target language.
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
      # notes_text = analyses.each_with_index.map { |a, i| "### 자료 #{i + 1}\n#{a[:notes]}" }.join("\n\n")
      notes_text = ""

      # Step 1: body
      Rails.logger.info "[OpenaiService] Step 1: Generating body..."
      body = generate_body(goal: goal, notes_text: notes_text)

      # Step 2: meta (본문 기반)
      Rails.logger.info "[OpenaiService] Step 2: Generating meta..."
      meta = generate_meta(goal: goal, body: body)

      meta.merge(body: body)
    end

    def translate_content(title:, description:, body:, target_locale:, cta_text: nil)
      locale_name = SUPPORTED_LOCALES[target_locale.to_sym]&.dig(:name) || target_locale.to_s.upcase
      prompt = +"#{TRANSLATION_PROMPT}\n\n"
      prompt << "## Target Language: #{locale_name}\nYou MUST write ALL output in #{locale_name}.\n\n"
      prompt << "## Content to Translate\n"
      prompt << "Title: #{title}\n"
      prompt << "Description: #{description}\n"
      prompt << "CTA Button Text: #{cta_text}\n" if cta_text.present?
      prompt << "Body:\n#{body}\n"

      schema_properties = {
        title:       { type: "string" },
        description: { type: "string" },
        body:        { type: "string" },
        cta_text:    { type: "string" }
      }

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
                properties: schema_properties,
                required: [ "title", "description", "body", "cta_text" ],
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

        글 목표에 맞는 블로그 본문을 작성해주세요.
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

      content = response.dig("choices", 0, "message", "content").to_s.strip
      content.gsub(/\A```(?:html)?\n?/, "").gsub(/\n?```\z/, "").strip
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
      article_text = article_text.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
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
      { title: parsed["title"], description: parsed["description"], body: parsed["body"], cta_text: parsed["cta_text"] }
    rescue JSON::ParserError => e
      Rails.logger.error "[OpenaiService] Failed to parse translation: #{e.message}"
      raise "Failed to parse AI translation response"
    end
  end
end
