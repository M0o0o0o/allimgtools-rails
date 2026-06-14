# /blog-pipeline

키워드를 받아 SEO 최적화된 영어 블로그 글을 자동 생성하고, 이미지까지 AI로 생성해 allimgtools DB에 저장하는 파이프라인입니다.

## 실행 방법

```
/blog-pipeline <키워드>
```

예시: `/blog-pipeline how to compress images for shopify`

---

## 사이트 컨텍스트

allimgtools는 이미지 압축·변환·리사이즈·EXIF 제거 등을 제공하는 웹 기반 이미지 툴 사이트입니다.

**타겟 독자**: Shopify 셀러, Instagram 크리에이터, WordPress 블로거, 웹 개발자

**블로그 목적**: SEO 트래픽 유입 → 툴 자연 연결 → 회원가입/구독 전환

---

## 글쓰기 원칙 (모든 단계에서 준수)

### 목소리 & 어조

- **2인칭 "you" 관점**으로 쓴다. "You can compress images in three steps."
- **Casual-professional**: 전문가가 동료에게 말하듯. 교수가 강의하는 톤 금지.
- **문장은 짧고 직접적으로**. 수동태 최소화. 축약형 사용 허용(can't, you'll, it's).
- **Mid-level 기술 수준**: JPEG·PNG·WebP 같은 기본 개념은 알고 있다고 가정. 처음 나오는 전문용어(AVIF, lossless, LCP)는 한 번만 간단히 정의.

### 절대 금지 표현 (AI-feel을 유발하는 패턴)

- `"In today's digital world..."` / `"In the age of..."` — 진부한 도입 문구
- `"It's worth noting that"` / `"Furthermore"` / `"Moreover"` — 학술 논문체
- `"In conclusion"` — 마지막 섹션 H2로 쓰지 않는다 (대신 "Wrapping Up" 또는 구체적 제목 사용)
- `"Absolutely!"` / `"Great news!"` — 감탄사형 시작
- `"Everything you need to know about"` — H2 제목에 금지
- `"The importance of"` — H2 제목에 금지
- 3단계 이상 중첩 리스트
- 모든 H2에 같은 패턴 반복 (예: "Step 1:", "Step 2:" 이외 섹션도 전부 "X: [설명]" 형식)

### H2 제목 스타일

- 독자의 실제 의문이나 상황을 짚는 표현
- 올바른 예: `"Why Your Images Are Failing Core Web Vitals"` / `"The Hidden Cost of Skipping Compression"`
- 금지: `"The Importance of Image Compression"` / `"Image Compression: Everything You Need to Know"`

### CTA 전략 (연구 결과 기반)

**핵심 원칙**: 툴은 문제에서 자연스럽게 등장하는 해결책이어야 한다. 글이 툴을 팔기 위해 존재하는 것처럼 보이면 안 된다.

1. **첫 언급 시점**: 글의 30% 이후. 그 전에는 교육적 내용에 집중.
2. **인라인 언급**: 글 전체에 1~2회. 여러 툴 옵션 중 하나로 소개하면 신뢰도 상승.
   - 압축 툴: `<a href="/compress">try our free image compressor</a>`
   - 변환 툴: `<a href="/convert">convert your images here</a>`
   - 리사이즈: `<a href="/resize">resize images online</a>`
   - EXIF 제거: `<a href="/exif">strip EXIF data free</a>`
3. **전용 섹션** (1,800단어 이상 글에만): 글의 60~70% 지점에 `<h2>How Allimgtools Handles [Topic]</h2>` 섹션 삽입. 200~400단어. UI 경험, 실제 압축률 수치, 사용 방법 포함.
4. **마지막 CTA 버튼**: 모든 글의 끝, FAQ 뒤에 단 하나. 짧고 행동 유발적인 텍스트.
   - `<div class="cta-box"><p>Ready to try it yourself? <a href="/compress" class="btn">Compress Your Images Free →</a></p></div>`
5. **짧은 글(400~600단어)**: 중간 배너 CTA 1개 + 마지막 버튼. 전용 섹션 불필요.

---

## 글 유형 & 분량 기준

경쟁사 6개 사이트(ShortPixel, Imagify, Kraken.io, ImageKit, Uploadcare, Cloudinary) 15개 글 분석 결과:

| 유형 | 설명 | 목표 분량 |
|------|------|----------|
| **유형A** | Quick how-to ("How do I...?", "Can I...?") | **400~600 words** |
| **유형B** | Explainer ("What is...?", "Why does...?") | **1,200~1,500 words** |
| **유형C** | Standard how-to guide (단계별 방법) | **1,800~2,200 words** |
| **유형D** | How-to + product integration (방법 + 툴 심층 연결) | **2,400~3,000 words** |
| **유형E** | Comparison / Buying guide (포맷·툴 비교, Best-of) | **3,200~4,000 words** |

---

## 유형별 구조 템플릿

### 유형A: Quick How-To (400~600 words)

```
1. Opening: 제목 질문에 대한 직접 답변 (1~2문장)
2. Available methods overview (방법 2~3가지 짧게)
3. Method 1: 단계 또는 코드
4. Method 2: 단계 또는 코드
5. Common issues (선택적 — 3열 표: Problem / Cause / Fix)
6. Next steps / Further reading 링크
7. 단일 CTA 버튼
```

필수 요소: `<!-- IMG_SLOT -->` 0~1개 (히어로 이미지만)

---

### 유형B: Explainer (1,200~1,500 words)

```
1. 도입: 구체적인 문제 상황 (1문단 — 제네릭 오프닝 금지)
2. Core concept: "what is X" 설명
3. Why it matters: 안 하면 어떤 결과? (수치/사례 포함)
4. How it works: 원리 또는 원인 2~3가지
5. Solutions overview: 2~3가지 옵션
6. 툴 언급 (1문단, 인라인 CTA 포함)
7. Key Takeaways (불릿 3~5개)
8. 단일 CTA 버튼
```

필수 요소: `<!-- IMG_SLOT -->` 1~3개 (히어로 + 차트/다이어그램)

---

### 유형C: Standard How-To Guide (1,800~2,200 words)

```
1. 도입: 문제 상황 (1문단)
2. Table of Contents (HTML 링크 목록)
3. Why this matters (1~2문단, 구체적 숫자 포함)
4. Prerequisites / What you'll need
5. Step-by-step 번호 리스트 (주요 내용 — H2 여러 개)
   - 각 단계: 행동 + 짧은 Why (왜 이 단계가 중요한가)
6. Common mistakes to avoid (불릿)
7. Quick Recap (불릿 3~5개)
8. FAQ (4~6개)
9. 단일 CTA 버튼
```

필수 요소: `<!-- IMG_SLOT -->` 2~4개 (히어로 + 주요 단계 스크린샷)

---

### 유형D: How-To + Product Integration (2,400~3,000 words)

```
1. 도입: 문제 상황 (1문단)
2. TL;DR 박스 + Key Takeaways (체크마크 불릿)
3. 개념 설명 ("What is X and why does quality matter?")
4. [N] Ways / Methods / Steps (H2 여러 개)
   - 각 방법: 실용적 단계 + 수치 + 예시
5. How to validate or measure results
6. Common mistakes (불릿)
7. "How Allimgtools Handles [Topic]" — 전용 섹션 (200~400 words)
   - UI 경험, 실제 압축률 예시, 사용 방법
8. FAQ (5~6개)
9. Wrapping Up (2~3문장)
10. 단일 CTA 버튼
```

필수 요소: `<!-- IMG_SLOT -->` 4~6개 (히어로 + 단계 스크린샷 + before/after + 툴 UI)

---

### 유형E: Comparison / Buying Guide (3,200~4,000 words)

```
1. 도입: 왜 이 선택이 중요한가 (1문단)
2. TL;DR / Quick Recommendation 박스 (결론 먼저)
3. Evaluation criteria H2 (선정 기준 설명)
4. Per-option reviews (H2 or H3 — 각 옵션 동일한 구조로):
   - What it is / Best for / Pros / Cons / Pricing
5. Summary comparison table (HTML — 툴 vs 기준, ✓/✗)
6. "How to Get Started with Allimgtools" — 전용 섹션
7. How to choose ("If you need X, go with Y" 형식)
8. FAQ (5~6개)
9. 단일 CTA 버튼
```

필수 요소: `<!-- IMG_SLOT -->` 6~10개 (히어로 + 옵션별 UI 스크린샷 + 비교 비주얼)

---

## 이미지 가이드라인 (연구 결과 기반)

### 이미지 유형 (효과 순)

1. **Before/after 비교** — 파일 크기, 화질, PageSpeed 점수. 항상 구체적 수치 포함. ("91% reduction, 5MB → 450KB")
2. **툴 UI 스크린샷** — 실제 사용 화면. 주요 기능에 화살표/콜아웃 표시.
3. **성능 지표 스크린샷** — PageSpeed Insights, GTmetrix, Lighthouse. 제3자 검증 역할.
4. **포맷/개념 다이어그램** — 브라우저 호환성 차트, 압축 파이프라인.
5. **비교 인포그래픽** — 포맷이나 툴을 5~7개 기준으로 시각적으로 비교.

### 이미지 배치 규칙

- **히어로 이미지**: 항상 첫 문단 전. Before/after 또는 개념 다이어그램 권장.
- **첫 본문 이미지**: 도입부 1~2문단 이후. 너무 일찍 삽입 금지.
- **툴 UI 스크린샷**: 전용 섹션 또는 단계별 설명 안에서만.
- **Before/after**: 해당 클레임 바로 아래 ("reduced from 2MB to 180KB" → 이미지 즉시 삽입).
- 이미지 2개 연속 배치 금지 — 반드시 텍스트 사이에 배치.
- **장식용 스톡 사진 절대 금지** — 모든 이미지는 기능적 목적이 있어야 한다.

---

## 오케스트레이터 지침

`/blog-pipeline <키워드>` 가 호출되면 아래 6단계를 **순차적으로** 실행한다.
각 단계는 이전 단계의 출력 파일을 읽어 처리한다.

작업 디렉토리: `tmp/blog_pipeline/<keyword_slug>/`
- keyword_slug = 키워드를 소문자 영문 하이픈으로 변환 (예: "how to compress images for shopify" → "compress-images-shopify")

시작 전: `mkdir -p tmp/blog_pipeline/<keyword_slug>/images` 로 디렉토리 생성

---

## STEP 1: Researcher

**목표**: 구글 상위 글들을 분석해 경쟁 구조와 콘텐츠 유형을 파악한다.

**지침**:

### 1-1. 검색 결과 수집

아래 Rails runner로 SerpAPI를 호출한다:

```bash
bin/kamal app exec --reuse "bin/rails runner -" << 'RUBY'
results = Crawlers::GoogleSearch.new.search(
  query: "<keyword>",
  gl: "us",
  hl: "en",
  num: 10
)
results.each_with_index do |r, i|
  puts "#{i+1}. #{r[:title]}"
  puts "   #{r[:link]}"
  puts "   #{r[:excerpt]}"
  puts
end
RUBY
```

SerpAPI 실패 시: `WebSearch`로 영어 키워드 직접 검색.

출력된 결과에서 블로그/가이드 URL을 최대 8개 추출한다.
(광고, 쇼핑, Reddit, Quora 제외 / 블로그·툴 사이트 가이드 우선)

### 1-2. 경쟁 글 분석

추출한 URL 중 **상위 5개**를 WebFetch로 fetch하여 분석한다:

- 제목 (H1)
- 주요 섹션 (H2 목록)
- 예상 단어 수 (추정)
- 글 유형: 유형A~E 중 하나로 분류
- 특이 구성 요소 (TL;DR 박스, 비교표, FAQ, 체크리스트, 코드 블록 등)
- CTA 위치 및 방식
- 도입부 방식 (문제 상황 / 질문 / 통계 / 반전)

### 1-3. research.md 작성

`tmp/blog_pipeline/<keyword_slug>/research.md` 에 저장:

```markdown
# Research: <keyword>
Date: <today>

## Keyword Analysis
- Main keyword:
- Related keywords:
- Search intent:
- Predicted content type: [유형A~E + 판단 근거]

## Competitor Analysis

### Rank 1: [Title](URL)
- Content type:
- H2 structure:
- Estimated word count:
- Notable elements:
- Intro hook style:
- CTA strategy:

### Rank 2: ...
(5개까지)

## Key Insights
- Average competitor word count:
- Differentiation opportunities: (경쟁글에 없는 각도, 포맷, 정보)
- Must-cover topics:
- Patterns to avoid: (AI-feel 구조 또는 과도하게 반복되는 패턴)
```

---

## STEP 2: Planner

**목표**: research.md를 바탕으로 글 유형을 확정하고 구조를 설계한다.

**지침**:

`tmp/blog_pipeline/<keyword_slug>/research.md` 를 읽는다.

### 2-1. 글 유형 확정

research.md의 예상 유형과 키워드 의도를 종합해 유형A~E 중 하나를 확정한다.

| 유형 | 키워드 패턴 | 독자 상태 |
|------|-----------|---------|
| A: Quick how-to | "How do I...", "Can I...", "Is it possible to..." | 빠른 답변 필요 |
| B: Explainer | "What is...", "Why does...", "How does...work" | 개념 이해 필요 |
| C: Standard how-to | "How to [동사]...", step-by-step 암시 | 방법을 모름 |
| D: How-to + product | "How to [동사] without [문제]", "[specific use case]" | 방법 + 최선의 툴 탐색 |
| E: Comparison | "[A] vs [B]", "best [tool/format] for [use case]", "top N" | 선택지 비교 중 |

### 2-2. 글 구조 설계 + 메타데이터 확정

1. **H1 제목** — 영어, 아래 공식 중 선택:
   - How-to형: `How To [동사] [목적어]: [부가 구체성]`
     → `How To Compress Images Without Losing Quality: A Practical Guide`
   - 숫자형: `[N] Ways To [동사] [목적어]`
     → `7 Ways To Reduce Image File Size Without Sacrificing Quality`
   - 질문형: `[Question]? [Answer Hint]`
     → `WebP vs JPG: Which Format Is Actually Better for Your Site?`
   - 비교형: `[A] vs [B]: [결정 기준]`
     → `AVIF vs WebP: Which Next-Gen Format Should You Use in 2025?`
   - Best형: `The Best [명사] For [독자/목적]`
     → `The Best Free Image Compressors for Shopify Sellers`

   **지켜야 할 것**: 구체적 독자/상황 명시 / 숫자·연도로 신뢰도 상승
   **금지**: `"Amazing"`, `"Ultimate Guide to"` (메인 제목에), `"Perfect"`, `"Breathtaking"`

2. **Meta description**: 150~160자, 핵심 키워드 + 행동 유발 문구
3. **Slug**: 소문자 하이픈, 핵심 키워드 포함
4. **Target word count**: 확정된 유형의 목표 범위 내에서 경쟁글 평균 참고
5. **Intro hook type**: Problem statement / Surprising stat / Common mistake / Named problem (Imagify "Image Tax" 방식)
6. **CTA 배치 계획**: 인라인 CTA 위치 + 전용 섹션 여부 + 마지막 버튼 문구
7. **IMG_SLOT 계획**: 몇 개, 어떤 종류의 이미지가 어느 섹션에 들어갈지

### 2-3. plan.md 작성

`tmp/blog_pipeline/<keyword_slug>/plan.md` 에 저장:

```markdown
# Plan: <keyword>

## Metadata
- H1:
- Meta description:
- Slug:
- Content type: [유형A~E]
- Target word count:

## Differentiation Points
-

## Intro Hook
- Type: [Problem statement / Surprising stat / Common mistake / Named problem]
- Opening sentence draft:
- Key data point or scenario to open with:

## CTA Plan
- Inline CTA (position + text + URL):
- Dedicated section: [yes/no, position in article]
- End CTA button text:

## IMG_SLOT Plan
- slot 1: [위치 + 설명]
- slot 2: ...

## Article Structure
(유형별 템플릿에 따라 섹션별 상세 기획)

### ① [Section Name]
- Content:
- H3 items (if any):
- IMG_SLOT here: [yes/no + description]
- CTA here: [yes/no]

(모든 섹션 반복)

## Internal Link Candidates
- [Anchor text] → [/posts/slug]
```

---

## STEP 3: Writer

**목표**: plan.md를 보고 완성도 높은 영어 초안을 작성한다.

**지침**:

`tmp/blog_pipeline/<keyword_slug>/plan.md` 를 읽는다.
위의 **글쓰기 원칙 (공통)** 과 **유형별 구조 템플릿** 을 엄수한다.

### 출력 형식

**HTML만** (ActionText/Rails rich text 호환)
- H2, H3, p, ul/li, ol/li, table(thead/tbody), strong, em
- TL;DR 박스: `<div class="tldr"><strong>TL;DR:</strong> 내용</div>`
- Key Takeaways: `<div class="key-takeaways"><strong>Key Takeaways:</strong><ul><li>✓ 내용</li></ul></div>`
- 인라인 CTA: `<a href="/compress">try our free image compressor</a>`
- CTA 버튼 박스: `<div class="cta-box"><p>내용 <a href="/tool" class="btn">버튼 텍스트 →</a></p></div>`
- 이미지 플레이스홀더: `<!-- IMG_SLOT: [구체적 설명] -->`
  - 예: `<!-- IMG_SLOT: Before/after showing 5MB product photo compressed to 320KB with quality intact -->`

H1 제외, body 내용만 `tmp/blog_pipeline/<keyword_slug>/draft.html` 에 저장.

---

## STEP 4: Reviewer

**목표**: 초안을 검토하고 최종본을 완성한다.

**지침**:

`tmp/blog_pipeline/<keyword_slug>/draft.html` 과 `plan.md` 를 읽는다.

### 공통 검토 항목

1. **목소리 일관성**: 2인칭("you/your") 또는 1인칭 복수("we/our tests") 중 하나로 일관
2. **키워드**: H1·메타·첫 문단에 자연스럽게 포함
3. **도입부 훅**: 첫 문장이 독자의 구체적 문제나 상황을 짚는가 (제네릭 오프닝 금지)
4. **금지 표현**: 위 글쓰기 원칙의 금지 목록 위반 여부
5. **단어 수**: plan.md 목표치 ±10% 범위
6. **CTA 배치**: plan.md의 CTA 계획과 일치, 인라인 1~2개 + 마지막 버튼
7. **IMG_SLOT**: plan.md 계획한 개수만큼 적절한 위치에 배치됐는지
8. **결론부**: "Wrapping Up" 또는 구체적 H2 제목으로 마무리. "In conclusion" 금지.

### 유형별 체크리스트

**유형A**:
- [ ] 첫 문장이 질문에 대한 직접 답변
- [ ] 방법이 2~3가지로 명확히 구분
- [ ] 전체 600단어 이내

**유형B**:
- [ ] 도입부에 구체적 문제 상황 (숫자 또는 시나리오)
- [ ] 개념 → 영향 → 원인 → 해결 순서 준수
- [ ] Key Takeaways 불릿 포함

**유형C**:
- [ ] Table of Contents 포함
- [ ] 단계가 번호 리스트(ol)로 구성
- [ ] 각 단계에 짧은 "Why" 포함
- [ ] Common mistakes 섹션
- [ ] Quick Recap 불릿
- [ ] FAQ 4~6개

**유형D**:
- [ ] TL;DR 박스 (도입부 직후)
- [ ] Key Takeaways 체크마크 불릿
- [ ] "How Allimgtools Handles [Topic]" 전용 섹션 (글의 60~70% 위치)
- [ ] FAQ 5~6개
- [ ] Wrapping Up 섹션

**유형E**:
- [ ] Quick Recommendation 박스 (결론 먼저)
- [ ] Evaluation criteria 섹션
- [ ] 각 옵션이 동일한 구조로 리뷰됨 (Best for / Pros / Cons)
- [ ] HTML 비교 테이블 (툴 vs 기준)
- [ ] "How to Get Started with Allimgtools" 전용 섹션
- [ ] "How to choose" 의사결정 섹션
- [ ] FAQ 5~6개

수정 사항 직접 반영 후 `tmp/blog_pipeline/<keyword_slug>/final.html` 로 저장.

파일 상단에 메타데이터 주석 포함:
```html
<!--
TITLE: [H1 제목]
DESCRIPTION: [메타 디스크립션]
SLUG: [slug]
CONTENT_TYPE: [유형A~E]
WORD_COUNT: [최종 단어 수 추정]
-->
```

---

## STEP 5: Image Generator

**목표**: final.html의 `<!-- IMG_SLOT: ... -->` 주석을 분석해 DALL-E 3으로 이미지를 생성하고 Active Storage에 업로드한 뒤 `<img>` 태그로 교체한다.

**지침**:

`tmp/blog_pipeline/<keyword_slug>/final.html` 을 읽는다.

### 5-1. 이미지 프롬프트 설계

각 `<!-- IMG_SLOT: ... -->` 주석에 대해 gpt-image-1 프롬프트를 작성한다.

**공통 스타일 지침**:
- 기본 톤: "clean flat design illustration, bold solid blue background (#2563EB or similar), white and light-colored icons/shapes, Google/Apple app-icon aesthetic, professional and modern"
- **텍스트 레이블 적극 활용**: 포맷명(HEIC, JPG, WebP, PNG), 수치(50%, 5MB, 320KB) 등 핵심 정보는 굵은 흰색 배지/라벨로 이미지 안에 포함
- 오브젝트는 흰색 테두리 또는 그림자로 배경과 분리감 부여
- 구체적이고 시각적인 장면 묘사 (추상 금지)
- Before/after 유형: 좌우 분할 또는 화살표 전후 대비, 수치 레이블 명시
- UI 목업 유형: 실제 앱 UI처럼 버튼·슬라이더·퍼센트 표시 포함
- 포맷 변환 유형: 두 포맷 아이콘을 배지 형태로 배치 + 변환 화살표

**프롬프트 예시**:
- 압축 before/after → `"Clean flat illustration on solid blue background, two image thumbnails side by side connected by a right-pointing arrow, left thumbnail labeled '5MB' badge, right thumbnail labeled '320KB' badge, white rounded rectangles with subtle shadow, bold white text labels, Google-style flat design, professional and modern"`
- 포맷 변환 → `"Flat design illustration on blue gradient background, large centered document/image icon in white, lower-left floating badge labeled 'HEIC' in dark blue rounded rectangle, lower-right floating badge labeled 'JPG' in white rounded rectangle, conversion arrow between badges, clean app-icon aesthetic, bold and simple"`
- 리사이즈 UI → `"Clean flat illustration on solid blue background, centered image frame icon with dashed selection handles at corners and sides, resize arrow pointing outward at top-right corner, two percentage badges '50%' and '100%' below in white rounded rectangles, professional minimal design"`
- 개념 다이어그램 → `"Clean flat infographic on blue background, three white rounded icon cards connected by arrows from left to right: camera icon → compress icon → fast rocket icon, each card has a short white label underneath, modern tech aesthetic"`

### 5-2. 이미지 생성 및 업로드

각 프롬프트에 대해 아래 Rails runner를 실행한다 (이미지 1개씩):

```bash
bin/kamal app exec --reuse "bin/rails runner -" << 'RUBY'
require "open-uri"

client = OpenAI::Client.new(access_token: Rails.application.credentials.dig(:openai, :api_key))

prompt = "<여기에_프롬프트>"
slot_index = <이미지_번호>  # 1, 2, 3...
keyword_slug = "<keyword_slug>"

response = client.images.generate(
  parameters: {
    model: "gpt-image-1",
    prompt: prompt,
    n: 1,
    size: "1536x1024",
    quality: "high"
  }
)

require "base64"

b64 = response.dig("data", 0, "b64_json")
raise "No image data returned" if b64.nil?

image_data = Base64.decode64(b64)
blob = ActiveStorage::Blob.create_and_upload!(
  io: StringIO.new(image_data),
  filename: "blog-#{keyword_slug}-#{slot_index}.png",
  content_type: "image/png"
)

signed_id = blob.signed_id
blob_path = "/rails/active_storage/blobs/redirect/#{signed_id}/#{blob.filename}"
puts "BLOB_KEY:#{blob.key}"
puts "BLOB_PATH:#{blob_path}"
RUBY
```

실패 시: 해당 슬롯 건너뛰고 원래 주석 유지. 계속 진행.

### 5-3. final.html 업데이트

각 `<!-- IMG_SLOT: ... -->` 주석을 생성된 이미지로 교체:

```html
<figure>
  <img src="<BLOB_PATH>" alt="<IMG_SLOT 설명>" loading="lazy" width="1536" height="1024">
</figure>
```

업데이트된 `tmp/blog_pipeline/<keyword_slug>/final.html` 저장. 메타데이터 주석 유지.

결과 출력:
```
🎨 Image Generation 완료
   생성됨 (N개):
   - slot 1: <설명> → <blob_key>
   생성 실패 (N개):
   - slot N: <설명> — 주석 유지됨
```

---

## STEP 6: Publisher

**목표**: final.html을 파싱해 allimgtools DB에 직접 삽입한다.

**지침**:

`tmp/blog_pipeline/<keyword_slug>/final.html` 을 읽어 메타데이터 주석에서 값을 파싱한다.

```bash
bin/kamal app exec --reuse "bin/rails runner -" << 'RUBY'
title       = "파싱된 H1 제목"
description = "파싱된 메타 디스크립션"
slug        = "파싱된-slug"

base_slug = slug
counter = 1
while Post.exists?(slug: slug)
  slug = "#{base_slug}-#{counter}"
  counter += 1
end

body_html = <<~HTML
  [final.html 전체 내용 (메타데이터 주석 제외, <img> 태그 포함)]
HTML

post = Post.new(slug: slug, status: :draft)

if post.save
  translation = post.translations.build(
    locale:      "en",
    title:       title,
    description: description
  )
  translation.body = body_html

  if translation.save
    puts "✅ 생성 완료: Post ##{post.id} — #{title}"
    puts "   슬러그: #{slug}"
    puts "   상태: draft (관리자 패널에서 검토 후 published 처리)"
  else
    puts "❌ Translation 저장 실패: #{translation.errors.full_messages.join(', ')}"
  end
else
  puts "❌ Post 저장 실패: #{post.errors.full_messages.join(', ')}"
end
RUBY
```

성공 시 출력:
```
✅ 파이프라인 완료!
   키워드: <keyword>
   제목: <title>
   콘텐츠 유형: <type>
   Post ID: <id>
   이미지: <N>개 삽입
   상태: draft
   다음 단계: /admin/posts/<id> 에서 검토 후 published 처리
```

---

## 오류 처리

- **SerpAPI 실패 시**: WebSearch로 대체
- **WebFetch 실패 시**: 해당 URL 건너뛰고 나머지로 진행, research.md에 "fetch failed" 기록
- **DALL-E 실패 시**: 해당 이미지 슬롯 건너뛰고 `<!-- IMG_SLOT: ... -->` 주석 유지, 계속 진행
- **DB 삽입 실패 시**: 오류 메시지 출력 후 final.html 경로 안내
- **슬러그 중복 시**: `-2`, `-3` 자동 추가

---

## 파일 구조 (실행 후)

```
tmp/blog_pipeline/<keyword_slug>/
├── research.md    ← SERP 분석 결과
├── plan.md        ← 글 구조 설계
├── draft.html     ← Writer 초안
├── final.html     ← Reviewer 최종본 (메타데이터 주석 + <img> 태그 포함)
└── images/        ← (참고용) 이미지 디렉토리
```

`tmp/` 는 `.gitignore` 에 포함되어 커밋되지 않습니다.
