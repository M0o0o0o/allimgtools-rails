import { Controller } from "@hotwired/stimulus";
import { uploadFiles, MAX_FILE_SIZE } from "lib/chunk_uploader";
import { showToast } from "lib/toast";

// Base controller shared by all image tool pages (compress, resize, …).
// Subclasses must override `processingStatusText` and `buildFormData()`.
export default class extends Controller {
  static targets = [
    "input",
    "dropzone",
    "dropzoneArea",
    "contentArea",
    "fileGrid",
    "progressArea",
    "status",
    "startBtn",
    "fixedActions",
    "dragOverlay",
    "sidebar",
  ];

  static values = {
    taskId: String,
    startUrl: String,
  };

  #files = [];
  #pendingUploads = 0;
  #state = "idle";
  #dragCounter = 0;
  #resizeHandler = null;
  #startRequested = false;
  #waitOverlay = null;
  #uploadIds = new Map(); // File → uploadId

  connect() {
    this.#setState("idle");
    this.#resizeHandler = () => {
      if (window.innerWidth >= 1024) {
        const modal = document.getElementById("settings-modal");
        if (modal?.open) modal.close();
      }
    };
    window.addEventListener("resize", this.#resizeHandler);
  }

  disconnect() {
    window.removeEventListener("resize", this.#resizeHandler);
  }

  // Override in subclass to change the "processing" status message.
  get processingStatusText() {
    return "Processing...";
  }

  // Override in subclass to append tool-specific params to FormData.
  buildFormData(_formData) {}

  // ── File selection ──────────────────────────────────────────────

  openFilePicker() {
    if (this.#state === "processing") return;
    this.inputTarget.click();
  }

  onFileChange() {
    const files = Array.from(this.inputTarget.files);
    this.inputTarget.value = "";
    this.#handleNewFiles(files);
  }

  onDragEnter(event) {
    event.preventDefault();
    this.#dragCounter++;
    if (this.#state === "idle") {
      this.dropzoneTarget.classList.add("border-primary", "bg-primary/10");
    } else {
      this.dragOverlayTarget.classList.remove("hidden");
    }
  }

  onDragOver(event) {
    event.preventDefault();
  }

  onDragLeave() {
    this.#dragCounter--;
    if (this.#dragCounter === 0) {
      this.#hideDragFeedback();
    }
  }

  onDrop(event) {
    event.preventDefault();
    this.#dragCounter = 0;
    this.#hideDragFeedback();
    this.#handleNewFiles(Array.from(event.dataTransfer.files));
  }

  #hideDragFeedback() {
    this.dropzoneTarget.classList.remove("border-primary", "bg-primary/10");
    this.dragOverlayTarget.classList.add("hidden");
  }

  #handleNewFiles(files) {
    if (this.#state === "processing") return;

    const valid = files.filter((f) => f.size <= MAX_FILE_SIZE);
    const oversized = files.filter((f) => f.size > MAX_FILE_SIZE);

    if (oversized.length > 0) {
      showToast(
        `${oversized.map((f) => f.name).join(", ")} exceed${oversized.length === 1 ? "s" : ""} the 5MB limit.`,
        "warning",
      );
    }

    if (valid.length === 0) return;

    this.#files = [...this.#files, ...valid];
    this.#renderPreviews();
    this.#uploadFiles(valid);
  }

  #renderPreviews() {
    const grid = this.fileGridTarget;
    grid.innerHTML = "";

    this.#files.forEach((file, index) => {
      const li = document.createElement("li");
      li.className =
        "relative rounded-xl overflow-hidden bg-base-100 shadow w-36 h-36 flex-shrink-0 flex items-center justify-center";

      const img = document.createElement("img");
      img.className = "w-full h-full object-cover";
      img.src = URL.createObjectURL(file);
      img.onload = () => URL.revokeObjectURL(img.src);

      const label = document.createElement("div");
      label.className =
        "absolute bottom-0 left-0 right-0 bg-black/50 px-2 py-1 truncate text-xs text-white";
      label.textContent = file.name;

      const removeBtn = document.createElement("button");
      removeBtn.type = "button";
      removeBtn.className =
        "absolute top-1 right-1 btn btn-circle btn-xs btn-error opacity-80 hover:opacity-100";
      removeBtn.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M6 18L18 6M6 6l12 12"/></svg>`;
      removeBtn.addEventListener("click", (e) => {
        e.stopPropagation();
        this.#removeFile(index);
      });

      li.appendChild(img);
      li.appendChild(label);
      li.appendChild(removeBtn);
      grid.appendChild(li);
    });
  }

  #removeFile(index) {
    this.#uploadIds.delete(this.#files[index]);
    this.#files = this.#files.filter((_, i) => i !== index);
    if (this.#files.length === 0) {
      this.#setState("idle");
    } else {
      this.#renderPreviews();
    }
  }

  // ── Upload ──────────────────────────────────────────────────────

  async #uploadFiles(files) {
    this.#pendingUploads += files.length;
    if (this.#state !== "processing") {
      this.#setState("uploading");
    }
    this.#updateStatus();

    await uploadFiles(files, this.taskIdValue, {
      onSuccess: (file, uploadId) => {
        this.#uploadIds.set(file, uploadId);
      },
      onError: (file, e) => {
        showToast(`Failed to upload ${file.name}: ${e.message}`);
        this.#files = this.#files.filter((f) => f !== file);
        if (this.#files.length === 0) {
          this.#setState("idle");
        } else {
          this.#renderPreviews();
        }
      },
      onFileSettled: () => {
        this.#pendingUploads--;
        this.#updateStatus();
        if (this.#pendingUploads === 0 && this.#state === "uploading") {
          this.#setState("ready");
          if (this.#startRequested) {
            this.startTool();
          }
        }
      },
    });
  }

  #updateStatus() {
    if (this.#pendingUploads > 0) {
      this.statusTarget.textContent = `Uploading ${this.#pendingUploads} file${this.#pendingUploads !== 1 ? "s" : ""}...`;
    }
  }

  // ── Settings ────────────────────────────────────────────────────

  openSettings() {
    document.getElementById("settings-modal").showModal();
  }

  // ── Start (shared flow) ─────────────────────────────────────────

  async startTool() {
    if (this.#state === "uploading") {
      this.#startRequested = true;
      this.#showWaitOverlay();
      return;
    }
    if (this.#state !== "ready") return;
    this.#startRequested = false;
    this.#hideWaitOverlay();
    this.#setState("processing");

    const modal = document.getElementById("settings-modal");
    if (modal && modal.open) modal.close();

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

    try {
      const formData = new FormData();
      formData.append("task_id", this.taskIdValue);
      this.#files.forEach((file) => {
        const uid = this.#uploadIds.get(file);
        if (uid) formData.append("upload_ids[]", uid);
      });
      this.buildFormData(formData);

      const response = await fetch(this.startUrlValue, {
        method: "POST",
        headers: { "X-CSRF-Token": csrfToken, Accept: "application/json" },
        body: formData,
      });

      const data = await response.json();
      if (!response.ok) throw new Error(data.error || "Failed to start.");

      window.location.href = data.download_url;
    } catch (e) {
      showToast(e.message);
      this.#setState("ready");
    }
  }

  // ── State machine ───────────────────────────────────────────────

  #setState(state) {
    this.#state = state;

    const isIdle = state === "idle";
    const isActive = !isIdle;
    const isProcessing = state === "processing";

    this.dropzoneAreaTarget.classList.toggle("hidden", isActive);
    this.contentAreaTarget.classList.toggle("hidden", isIdle);
    this.progressAreaTarget.classList.toggle("hidden", !isProcessing);

    if (isProcessing) {
      this.statusTarget.textContent = this.processingStatusText;
    }

    this.startBtnTargets.forEach(
      (btn) => (btn.disabled = isIdle || isProcessing),
    );
    this.fixedActionsTargets.forEach((el) =>
      el.classList.toggle("hidden", isIdle),
    );

    // sidebar: force-hide when idle via inline style so it overrides lg:flex
    this.sidebarTargets.forEach((el) => {
      el.style.display = isIdle ? "none" : "";
    });

    if (isIdle) {
      this.#startRequested = false;
      this.#hideWaitOverlay();
      this.#uploadIds.clear();
      this.fileGridTarget.innerHTML = "";
    }
  }

  #showWaitOverlay() {
    if (this.#waitOverlay) return;
    const overlay = document.createElement("div");
    overlay.className =
      "absolute inset-0 z-30 bg-base-100/80 backdrop-blur-sm flex flex-col items-center justify-center gap-3";
    overlay.innerHTML = `
      <span class="loading loading-spinner loading-lg text-primary"></span>
      <p class="text-sm text-base-content/60">Waiting for upload to finish...</p>
    `;
    this.element.appendChild(overlay);
    this.#waitOverlay = overlay;
  }

  #hideWaitOverlay() {
    this.#waitOverlay?.remove();
    this.#waitOverlay = null;
  }
}
