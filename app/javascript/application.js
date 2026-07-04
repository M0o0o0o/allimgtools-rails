// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import "trix"
import "@rails/actiontext"

/* ==========================================================================
   TRIX EDITOR CUSTOMIZATION
   - H2/H3/H4 헤딩 추가
   - 텍스트 색상 선택기 (7색)
   - 이미지 라이브러리 버튼
   ========================================================================== */

/* --- 1. Heading 설정 --- */
Trix.config.blockAttributes.heading1.tagName = "h2"

Trix.config.blockAttributes.heading2 = {
  tagName: "h3",
  terminal: true,
  breakOnReturn: true,
  group: false,
}

Trix.config.blockAttributes.heading3 = {
  tagName: "h4",
  terminal: true,
  breakOnReturn: true,
  group: false,
}

/* --- 2. 텍스트 색상 설정 --- */
const textColors = {
  black:  "#000000",
  red:    "#e53935",
  orange: "#fb8c00",
  yellow: "#fdd835",
  green:  "#43a047",
  blue:   "#1e88e5",
  purple: "#8e24aa",
}

Object.entries(textColors).forEach(([name, color]) => {
  Trix.config.textAttributes[`color-${name}`] = {
    style: { color },
    inheritable: true,
    parser: (element) => element.style.color === color,
  }
})

/* --- 3. 툴바 UI 초기화 --- */
document.addEventListener("trix-initialize", function (event) {
  const editor  = event.target
  const toolbar = editor.toolbarElement
  const blockTools = toolbar.querySelector("[data-trix-button-group='block-tools']")
  const textTools  = toolbar.querySelector("[data-trix-button-group='text-tools']")

  // H3 버튼
  if (blockTools) {
    const h3Button = document.createElement("button")
    h3Button.setAttribute("type", "button")
    h3Button.setAttribute("tabindex", "-1")
    h3Button.setAttribute("title", "Heading 3")
    h3Button.className = "trix-button trix-button--icon trix-button--icon-heading-2"
    h3Button.setAttribute("data-trix-attribute", "heading2")
    h3Button.textContent = "H3"

    // H4 버튼
    const h4Button = document.createElement("button")
    h4Button.setAttribute("type", "button")
    h4Button.setAttribute("tabindex", "-1")
    h4Button.setAttribute("title", "Heading 4")
    h4Button.className = "trix-button trix-button--icon trix-button--icon-heading-3"
    h4Button.setAttribute("data-trix-attribute", "heading3")
    h4Button.textContent = "H4"

    const h2Button = blockTools.querySelector("[data-trix-attribute='heading1']")
    if (h2Button) {
      h2Button.textContent = "H2"
      h2Button.insertAdjacentElement("afterend", h4Button)
      h2Button.insertAdjacentElement("afterend", h3Button)
    }
  }

  // 컬러 피커
  if (textTools) {
    const colorWrapper  = document.createElement("div")
    colorWrapper.className = "trix-color-picker-wrapper"

    const colorButton = document.createElement("button")
    colorButton.setAttribute("type", "button")
    colorButton.className = "trix-button trix-button--color"
    colorButton.setAttribute("title", "Text Color")
    colorButton.setAttribute("tabindex", "-1")
    colorButton.innerHTML = "A"

    const colorDropdown = document.createElement("div")
    colorDropdown.className = "trix-color-dropdown"

    Object.entries(textColors).forEach(([name, color]) => {
      const option = document.createElement("button")
      option.setAttribute("type", "button")
      option.className = "trix-color-option"
      option.style.backgroundColor = color
      option.setAttribute("title", name)
      option.addEventListener("click", (e) => {
        e.preventDefault()
        Object.keys(textColors).forEach((c) => {
          if (editor.editor.attributeIsActive(`color-${c}`)) {
            editor.editor.deactivateAttribute(`color-${c}`)
          }
        })
        editor.editor.activateAttribute(`color-${name}`)
        colorDropdown.classList.remove("active")
      })
      colorDropdown.appendChild(option)
    })

    const resetOption = document.createElement("button")
    resetOption.setAttribute("type", "button")
    resetOption.className = "trix-color-option trix-color-reset"
    resetOption.setAttribute("title", "Remove color")
    resetOption.textContent = "✕"
    resetOption.addEventListener("click", (e) => {
      e.preventDefault()
      Object.keys(textColors).forEach((c) => {
        if (editor.editor.attributeIsActive(`color-${c}`)) {
          editor.editor.deactivateAttribute(`color-${c}`)
        }
      })
      colorDropdown.classList.remove("active")
    })
    colorDropdown.appendChild(resetOption)

    colorButton.addEventListener("click", (e) => {
      e.preventDefault()
      e.stopPropagation()
      const rect = colorButton.getBoundingClientRect()
      colorDropdown.style.top  = `${rect.bottom + 2}px`
      colorDropdown.style.left = `${rect.left}px`
      colorDropdown.classList.toggle("active")
    })

    document.addEventListener("click", (e) => {
      if (!colorWrapper.contains(e.target)) {
        colorDropdown.classList.remove("active")
      }
    })

    colorWrapper.appendChild(colorButton)
    colorWrapper.appendChild(colorDropdown)
    textTools.appendChild(colorWrapper)
  }

  // 이미지 라이브러리 버튼
  const fileTools = toolbar.querySelector("[data-trix-button-group='file-tools']")
  if (fileTools) {
    const libraryButton = document.createElement("button")
    libraryButton.setAttribute("type", "button")
    libraryButton.setAttribute("class", "trix-button")
    libraryButton.setAttribute("title", "이미지 라이브러리")
    libraryButton.setAttribute("tabindex", "-1")
    libraryButton.innerText = "라이브러리"
    libraryButton.addEventListener("click", (e) => {
      e.preventDefault()
      e.stopPropagation()
      document.dispatchEvent(
        new CustomEvent("open-image-library", {
          detail: { mode: "editor", editorElement: editor },
        })
      )
    })
    fileTools.appendChild(libraryButton)
  }
})

/* ==========================================================================
   TRIX IMAGE UPLOAD → Admin::UploadsController (WebP 변환 + MD5 중복 감지)
   - ActionText 기본 direct_upload 차단 후 /uploads 경유
   - sgid 반환으로 proper ActionText attachment 유지
   ========================================================================== */
document.addEventListener("trix-attachment-add", function (event) {
  const { attachment } = event
  if (!attachment.file) return

  event.stopImmediatePropagation()

  const formData  = new FormData()
  formData.append("file", attachment.file)

  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
  attachment.setUploadProgress(0)

  fetch("/uploads", {
    method: "POST",
    headers: { "X-CSRF-Token": csrfToken },
    body: formData,
  })
    .then((r) => r.json())
    .then(({ sgid, url, content_type, filename, filesize, error }) => {
      if (error || !sgid) { attachment.remove(); return }
      attachment.setAttributes({ sgid, url, href: url, content_type, filename, filesize, previewable: true })
      attachment.setUploadProgress(100)
    })
    .catch(() => attachment.remove())
}, true)

/* ==========================================================================
   TRIX TABLE PRESERVATION
   Trix는 <table>을 지원하지 않아 로드 시 구조를 제거합니다.
   - trix-initialize: data-original-html 속성에서 원본 HTML을 읽어
     테이블을 [[TABLE_N]] blockquote 마커로 교체 후 에디터에 로드
   - submit(capture): 마커를 원본 테이블 HTML로 복원 후 전송
   ※ DOMContentLoaded/turbo:load 방식은 Trix가 이미 content를 처리한
     뒤에 실행되므로 신뢰할 수 없음. trix-initialize 안에서 처리해야 함.
   ========================================================================== */
const _trixTableStore = new Map() // inputId → string[]

document.addEventListener("trix-initialize", function(event) {
  const editor   = event.target
  const inputId  = editor.getAttribute("input")
  if (!inputId || _trixTableStore.has(inputId)) return

  const originalHtml = editor.dataset.originalHtml || ""
  if (!originalHtml.includes("<table")) return

  const tables = []
  const processed = originalHtml.replace(/<table[\s\S]*?<\/table>/gi, match => {
    const i = tables.length
    tables.push(match)
    return `<blockquote>[[TABLE_${i}]]</blockquote>`
  })

  _trixTableStore.set(inputId, tables)

  // setTimeout(0): trix-initialize 콜백 밖에서 loadHTML을 호출해야 안전함
  setTimeout(() => {
    editor.editor.loadHTML(processed)

    const banner = document.createElement("div")
    banner.className = "bg-amber-50 border border-amber-300 text-amber-800 text-xs px-3 py-2 rounded mb-1"
    banner.textContent = `이 본문에 HTML 테이블 ${tables.length}개 포함 — 에디터에서는 [[TABLE_N]]으로 표시되며 저장 시 자동 복원됩니다.`
    editor.insertAdjacentElement("beforebegin", banner)
  }, 0)
})

document.addEventListener("submit", function(event) {
  const form = event.target
  _trixTableStore.forEach((tables, inputId) => {
    const input = document.getElementById(inputId)
    if (!input || !form.contains(input)) return
    let html = input.value
    tables.forEach((tableHtml, i) => {
      // Trix가 blockquote 내부를 약간 다르게 직렬화할 수 있으므로
      // 속성·공백·내부 태그를 허용하는 유연한 정규식 사용
      html = html.replace(
        new RegExp(`<blockquote[^>]*>\\s*(?:<[^/][^>]*>\\s*)*\\[\\[TABLE_${i}\\]\\]\\s*(?:<\\/[^>]+>\\s*)*<\\/blockquote>`, "gi"),
        tableHtml
      )
    })
    input.value = html
  })
}, true)
