import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "grid"]

  connect() {
    this._handleOpen = this.handleOpen.bind(this)
    document.addEventListener("open-image-library", this._handleOpen)
  }

  disconnect() {
    document.removeEventListener("open-image-library", this._handleOpen)
  }

  handleOpen(event) {
    this.mode          = event.detail.mode
    this.editorElement = event.detail.editorElement || null
    this.modalTarget.classList.remove("hidden")
    this.loadImages()
  }

  close() {
    this.modalTarget.classList.add("hidden")
  }

  closeOnBackdrop(event) {
    if (event.target === this.modalTarget) this.close()
  }

  async loadImages() {
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      const res  = await fetch("/uploads", {
        headers: { "X-CSRF-Token": csrfToken, "Accept": "application/json" }
      })
      const images = await res.json()

      this.gridTarget.innerHTML = images.map((img) => `
        <button type="button"
                class="aspect-square rounded-lg overflow-hidden border-2 border-transparent hover:border-primary transition"
                data-action="click->image-library#select"
                data-sgid="${img.sgid}"
                data-url="${img.url}"
                data-filename="${img.filename}"
                data-filesize="${img.filesize}"
                data-content-type="${img.content_type}">
          <img src="${img.url}" alt="${img.filename}" class="w-full h-full object-cover">
        </button>
      `).join("")

      if (images.length === 0) {
        this.gridTarget.innerHTML = `<p class="col-span-4 text-center text-base-content/50 py-8">업로드된 이미지가 없습니다.</p>`
      }
    } catch {
      this.gridTarget.innerHTML = `<p class="col-span-4 text-center text-error py-8">이미지를 불러오지 못했습니다.</p>`
    }
  }

  select(event) {
    const btn = event.currentTarget
    const { sgid, url, filename, filesize, contentType } = btn.dataset

    if (this.mode === "editor" && this.editorElement) {
      const attachment = new Trix.Attachment({
        sgid,
        url,
        href: url,
        content_type: contentType,
        filename,
        filesize: parseInt(filesize),
        previewable: true,
      })
      this.editorElement.editor.insertAttachment(attachment)
    }

    this.close()
  }
}
