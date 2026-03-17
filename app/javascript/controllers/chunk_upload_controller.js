import { Controller } from "@hotwired/stimulus";

const CHUNK_SIZE = 2 * 1024 * 1024; // 2MB
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

export default class extends Controller {
  static targets = [
    "input",
    "progress",
    "status",
    "submit",
    "dropzone",
    "preview",
    "progressArea",
    "errorAlert",
    "errorMessage",
  ];
  static values = { successPath: String, taskId: String };

  #files = [];

  // ── File selection ─────────────────────────────────────────

  openFilePicker() {
    this.inputTarget.click();
  }

  onFileChange() {
    this.#setFiles(Array.from(this.inputTarget.files));
  }

  onDragOver(event) {
    event.preventDefault();
    this.dropzoneTarget.classList.add("border-primary", "bg-primary/10");
  }

  onDragLeave() {
    this.dropzoneTarget.classList.remove("border-primary", "bg-primary/10");
  }

  onDrop(event) {
    event.preventDefault();
    this.dropzoneTarget.classList.remove("border-primary", "bg-primary/10");
    this.#setFiles(Array.from(event.dataTransfer.files));
  }

  #setFiles(files) {
    this.#files = files;
    this.#renderPreviews();
    this.submitTarget.disabled = files.length === 0;
    this.#hideError();
  }

  #renderPreviews() {
    const list = this.previewTarget;
    list.innerHTML = "";

    if (this.#files.length === 0) {
      list.classList.add("hidden");
      return;
    }

    list.classList.remove("hidden");

    this.#files.forEach((file, index) => {
      const li = document.createElement("li");
      li.className =
        "relative rounded-xl overflow-hidden bg-base-100 shadow aspect-square flex items-center justify-center";

      if (file.size > MAX_FILE_SIZE) {
        li.innerHTML = `
          <div class="absolute inset-0 bg-error/10 flex flex-col items-center justify-center p-2 text-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-error mb-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/>
            </svg>
            <p class="text-xs text-error font-medium leading-tight">${file.name}</p>
            <p class="text-xs text-error/70">Exceeds 5MB</p>
          </div>`;
      } else {
        const img = document.createElement("img");
        img.className = "w-full h-full object-cover";
        img.src = URL.createObjectURL(file);
        img.onload = () => URL.revokeObjectURL(img.src);

        const label = document.createElement("div");
        label.className =
          "absolute bottom-0 left-0 right-0 bg-black/50 px-2 py-1 truncate text-xs text-white";
        label.textContent = file.name;

        li.appendChild(img);
        li.appendChild(label);
      }

      const removeBtn = document.createElement("button");
      removeBtn.type = "button";
      removeBtn.className =
        "absolute top-1 right-1 btn btn-circle btn-xs btn-error opacity-80 hover:opacity-100";
      removeBtn.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M6 18L18 6M6 6l12 12"/></svg>`;
      removeBtn.addEventListener("click", (e) => {
        e.stopPropagation();
        this.#removeFile(index);
      });

      li.appendChild(removeBtn);
      list.appendChild(li);
    });
  }

  #removeFile(index) {
    this.#files = this.#files.filter((_, i) => i !== index);
    this.#renderPreviews();
    this.submitTarget.disabled = this.#files.length === 0;
  }

  // ── Upload ──────────────────────────────────────────────────

  async upload(event) {
    event.preventDefault();

    if (this.#files.length === 0) return;

    const taskId = this.taskIdValue;
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

    this.submitTarget.disabled = true;
    this.progressAreaTarget.classList.remove("hidden");
    this.#hideError();

    try {
      for (let i = 0; i < this.#files.length; i++) {
        const file = this.#files[i];

        if (file.size > MAX_FILE_SIZE) {
          throw new Error(`${file.name} exceeds the 5MB size limit.`);
        }

        this.statusTarget.textContent = `File ${i + 1}/${this.#files.length}: ${file.name} uploading...`;
        this.progressTarget.value = 0;

        await this.#uploadFile(file, taskId, csrfToken);

        this.progressTarget.value = Math.round(
          ((i + 1) / this.#files.length) * 100,
        );
      }

      this.statusTarget.textContent = "Upload complete! Redirecting...";
      window.location.href = `${this.successPathValue}/${taskId}`;
    } catch (e) {
      this.#showError(e.message);
      this.progressAreaTarget.classList.add("hidden");
      this.submitTarget.disabled = false;
    }
  }

  async #uploadFile(file, taskId, csrfToken) {
    const uploadId = crypto.randomUUID();
    const totalChunks = Math.ceil(file.size / CHUNK_SIZE);

    for (let i = 0; i < totalChunks; i++) {
      const start = i * CHUNK_SIZE;
      const end = Math.min(start + CHUNK_SIZE, file.size);

      const formData = new FormData();
      formData.append("upload_id", uploadId);
      formData.append("task_id", taskId);
      formData.append("chunk_index", i);
      formData.append("total_chunks", totalChunks);
      formData.append("filename", file.name);
      formData.append("chunk", file.slice(start, end));

      const response = await fetch("/uploads/chunk", {
        method: "POST",
        headers: { "X-CSRF-Token": csrfToken },
        body: formData,
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || "Upload failed.");
      }

      this.statusTarget.textContent = `${file.name}: ${Math.round(((i + 1) / totalChunks) * 100)}%`;
    }
  }

  // ── Error display ────────────────────────────────────────────

  #showError(message) {
    this.errorMessageTarget.textContent = message;
    this.errorAlertTarget.classList.remove("hidden");
  }

  #hideError() {
    this.errorAlertTarget.classList.add("hidden");
    this.errorMessageTarget.textContent = "";
  }
}
