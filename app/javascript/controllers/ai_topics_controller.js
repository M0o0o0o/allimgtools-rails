import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "goalInput",
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

    const goal = this.goalInputTarget.value.trim()

    if (!goal) {
      alert("글 목표를 입력해주세요.")
      return
    }

    this.topics.push({ id: this.nextId++, goal })
    this.goalInputTarget.value = ""
    this.goalInputTarget.focus()
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
      <input type="hidden" name="goals[${index}]" value="${this.escapeHtml(t.goal)}">
    `).join("")

    const hasTopic = this.topics.length > 0
    this.emptyStateTarget.classList.toggle("hidden", hasTopic)
    this.topicsListTarget.classList.toggle("hidden", !hasTopic)
    this.generateBtnTarget.disabled = !hasTopic
    this.topicCountTarget.textContent = `${this.topics.length}개의 목표`
  }

  topicTemplate(topic) {
    return `
      <div class="flex items-center justify-between p-3 bg-base-200 rounded-lg">
        <div class="flex-1">
          <p class="font-medium">${this.escapeHtml(topic.goal)}</p>
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
