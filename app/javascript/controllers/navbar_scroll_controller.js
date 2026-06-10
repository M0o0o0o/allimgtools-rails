import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.update = this.update.bind(this)
    window.addEventListener("scroll", this.update, { passive: true })
    this.update()
  }

  disconnect() {
    window.removeEventListener("scroll", this.update)
  }

  update() {
    const scrolled = window.scrollY > 10
    this.element.classList.toggle("bg-base-100", !scrolled)
    this.element.classList.toggle("bg-base-100/80", scrolled)
    this.element.classList.toggle("backdrop-blur-md", scrolled)
    this.element.classList.toggle("shadow-sm", scrolled)
  }
}
