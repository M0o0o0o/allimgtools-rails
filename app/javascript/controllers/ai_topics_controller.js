import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "topicInput",
    "searchQueryInput",
    "topicsList",
    "emptyState",
    "form",
    "hiddenInputs",
    "generateBtn",
    "topicCount"
  ]

  topics = []
  nextId = 0

  connect() {
    this.updateUI()
  }

  addTopic(event) {
    if (event.type === "keydown" && event.key !== "Enter") return
    event.preventDefault()

    const topic = this.topicInputTarget.value.trim()
    const searchQuery = this.searchQueryInputTarget.value.trim()

    if (!topic) {
      alert("주제를 입력해주세요.")
      return
    }

    if (!searchQuery) {
      alert("영어 검색어를 입력해주세요.")
      return
    }

    this.topics.push({ id: this.nextId++, topic, searchQuery })
    this.topicInputTarget.value = ""
    this.searchQueryInputTarget.value = ""
    this.topicInputTarget.focus()
    this.updateUI()
  }

  removeTopic(event) {
    const id = parseInt(event.currentTarget.dataset.id)
    this.topics = this.topics.filter(t => t.id !== id)
    this.updateUI()
  }

  updateUI() {
    this.topicsListTarget.innerHTML = this.topics.map(t => this.topicTemplate(t)).join("")

    this.hiddenInputsTarget.innerHTML = this.topics.map((t, index) => `
      <input type="hidden" name="topics[${index}][topic]" value="${this.escapeHtml(t.topic)}">
      <input type="hidden" name="topics[${index}][search_query]" value="${this.escapeHtml(t.searchQuery)}">
    `).join("")

    const hasTopic = this.topics.length > 0
    this.emptyStateTarget.classList.toggle("hidden", hasTopic)
    this.topicsListTarget.classList.toggle("hidden", !hasTopic)
    this.generateBtnTarget.disabled = !hasTopic
    this.topicCountTarget.textContent = `${this.topics.length}개의 주제`
  }

  topicTemplate(topic) {
    return `
      <div class="flex items-center justify-between p-3 bg-base-200 rounded-lg">
        <div class="flex-1">
          <p class="font-medium">${this.escapeHtml(topic.topic)}</p>
          <p class="text-sm text-base-content/60 mt-0.5">${this.escapeHtml(topic.searchQuery)}</p>
        </div>
        <button type="button"
                data-id="${topic.id}"
                data-action="click->ai-topics#removeTopic"
                class="btn btn-ghost btn-xs text-error ml-4">
          삭제
        </button>
      </div>
    `
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
