import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "toc", "tocNav"]

  connect() {
    this.buildToc()
    this.enhanceTables()
    this.enhanceImageRows()
  }

  disconnect() {
    this.observer?.disconnect()
  }

  buildToc() {
    const headings = Array.from(this.contentTarget.querySelectorAll("h2, h3, h4"))
    if (headings.length < 2) return

    headings.forEach((h, i) => { if (!h.id) h.id = `section-${i}` })

    const navHtml = headings.map(h => {
      const indent = (parseInt(h.tagName[1]) - 2) * 12
      return `<a href="#${h.id}"
        class="toc-link block py-1 text-sm text-base-content/50 hover:text-primary transition-colors leading-snug"
        style="padding-left:${indent}px"
        data-heading-id="${h.id}"
        data-action="click->table-of-contents#smoothScroll">${h.textContent.trim()}</a>`
    }).join("")

    if (this.hasTocTarget) {
      this.tocNavTarget.innerHTML = navHtml
      this.tocTarget.classList.remove("hidden")
    }

    this.setupScrollSpy(headings)
  }

  smoothScroll(event) {
    event.preventDefault()
    const el = document.getElementById(event.currentTarget.dataset.headingId)
    el?.scrollIntoView({ behavior: "smooth", block: "start" })
  }

  enhanceImageRows() {
    const processed = new Set()
    this.contentTarget.querySelectorAll("figure").forEach(figure => {
      if (processed.has(figure)) return
      if (figure.parentElement.classList.contains("image-row")) return

      const group = [figure]
      let next = figure.nextElementSibling
      while (next && next.tagName === "FIGURE") {
        group.push(next)
        next = next.nextElementSibling
      }
      group.forEach(f => processed.add(f))
      if (group.length < 2) return

      const wrapper = document.createElement("div")
      wrapper.className = "image-row"
      figure.parentNode.insertBefore(wrapper, figure)
      group.forEach(f => wrapper.appendChild(f))
    })
  }

  enhanceTables() {
    this.contentTarget.querySelectorAll("table").forEach(table => {
      if (table.parentElement.classList.contains("table-wrapper")) return
      const wrapper = document.createElement("div")
      wrapper.className = "table-wrapper"
      table.parentNode.insertBefore(wrapper, table)
      wrapper.appendChild(table)
    })
  }

  setupScrollSpy(headings) {
    this.observer = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) this.#highlight(entry.target.id)
      })
    }, { rootMargin: "-15% 0px -75% 0px" })
    headings.forEach(h => this.observer.observe(h))
  }

  #highlight(activeId) {
    this.element.querySelectorAll(".toc-link").forEach(link => {
      const active = link.dataset.headingId === activeId
      link.classList.toggle("text-primary",         active)
      link.classList.toggle("font-semibold",         active)
      link.classList.toggle("text-base-content/50", !active)
    })
  }
}
