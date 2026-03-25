import { Controller } from "@hotwired/stimulus";
import { uploadFiles, MAX_FILE_SIZE } from "lib/chunk_uploader";
import { showToast } from "lib/toast";

export default class extends Controller {
  static targets = [
    "input",
    "dropzoneArea",
    "contentArea",
    "previewImg",
    "startBtn",
    "dragOverlay",
    "progressArea",
    "status",
  ];

  static values = {
    taskId: String,
    startUrl: String,
    rotate: { type: Number, default: 0 },
  };

  #uploadId = null;
  #state = "idle"; // idle | uploading | ready | processing
  #startRequested = false;
  #waitOverlay = null;
  #dragCounter = 0;
  #visualRotation = 0; // Accumulated degrees for CSS animation (never wraps)

  connect() {
    this.#setState("idle");
  }

  // ── File selection ───────────────────────────────────────────────

  openFilePicker() {
    if (this.#state === "processing") return;
    this.inputTarget.click();
  }

  onFileChange() {
    const files = Array.from(this.inputTarget.files);
    this.inputTarget.value = "";
    if (files[0]) this.#handleFile(files[0]);
  }

  onDragEnter(event) {
    event.preventDefault();
    this.#dragCounter++;
    this.dragOverlayTarget.classList.remove("hidden");
  }

  onDragOver(event) {
    event.preventDefault();
  }

  onDragLeave() {
    this.#dragCounter--;
    if (this.#dragCounter === 0) this.dragOverlayTarget.classList.add("hidden");
  }

  onDrop(event) {
    event.preventDefault();
    this.#dragCounter = 0;
    this.dragOverlayTarget.classList.add("hidden");
    const files = Array.from(event.dataTransfer.files);
    if (files[0]) this.#handleFile(files[0]);
  }

  #handleFile(file) {
    if (this.#state === "processing") return;

    if (file.size > MAX_FILE_SIZE) {
      showToast(`${file.name} exceeds the 5MB limit.`, "warning");
      return;
    }

    this.#uploadId = null;
    this.#startRequested = false;
    this.rotateValue = 0;

    const img = this.previewImgTarget;
    const url = URL.createObjectURL(file);
    img.src = url;
    img.onload = () => URL.revokeObjectURL(url);

    this.#setState("uploading");
    this.#uploadFile(file);
  }

  // ── Upload ───────────────────────────────────────────────────────

  async #uploadFile(file) {
    await uploadFiles([file], this.taskIdValue, {
      onSuccess: (_f, uploadId) => {
        this.#uploadId = uploadId;
      },
      onError: (_f, e) => {
        showToast(`Failed to upload ${file.name}: ${e.message}`);
        this.#setState("idle");
      },
      onFileSettled: () => {
        if (this.#uploadId) {
          this.#setState("ready");
          if (this.#startRequested) this.startRotate();
        }
      },
    });
  }

  // ── Rotation ─────────────────────────────────────────────────────

  rotateLeft() {
    this.#visualRotation -= 90;
    this.rotateValue = ((this.#visualRotation % 360) + 360) % 360;
    this.#updatePreviewTransform();
  }

  rotateRight() {
    this.#visualRotation += 90;
    this.rotateValue = ((this.#visualRotation % 360) + 360) % 360;
    this.#updatePreviewTransform();
  }

  rotateValueChanged() {
    // intentionally empty — preview is updated directly in rotateLeft/rotateRight
  }

  #updatePreviewTransform() {
    if (!this.hasPreviewImgTarget) return;
    this.previewImgTarget.style.transform =
      this.#visualRotation !== 0 ? `rotate(${this.#visualRotation}deg)` : "";
  }

  resetImage() {
    this.#setState("idle");
  }

  // ── Start ────────────────────────────────────────────────────────

  startRotate() {
    if (this.#state === "uploading") {
      this.#startRequested = true;
      this.#showWaitOverlay();
      return;
    }
    if (this.#state !== "ready") return;
    this.#startRequested = false;
    this.#hideWaitOverlay();
    this.#setState("processing");

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

    const formData = new FormData();
    formData.append("task_id", this.taskIdValue);
    formData.append("upload_id", this.#uploadId);
    formData.append("rotate", this.rotateValue);

    fetch(this.startUrlValue, {
      method: "POST",
      headers: { "X-CSRF-Token": csrfToken, Accept: "application/json" },
      body: formData,
    })
      .then((res) => res.json().then((data) => ({ ok: res.ok, data })))
      .then(({ ok, data }) => {
        if (!ok) throw new Error(data.error || "Failed to start.");
        window.location.href = data.download_url;
      })
      .catch((e) => {
        showToast(e.message);
        this.#setState("ready");
      });
  }

  // ── State ────────────────────────────────────────────────────────

  #setState(state) {
    this.#state = state;
    const isIdle = state === "idle";
    const isProcessing = state === "processing";

    this.dropzoneAreaTarget.classList.toggle("hidden", !isIdle);
    this.contentAreaTarget.classList.toggle("hidden", isIdle);
    this.progressAreaTarget.classList.toggle("hidden", !isProcessing);

    if (isProcessing) {
      this.statusTarget.textContent = "Rotating image...";
    }

    this.startBtnTargets.forEach((btn) => (btn.disabled = isIdle || isProcessing));

    if (isIdle) {
      this.#startRequested = false;
      this.#hideWaitOverlay();
      this.#uploadId = null;
      this.rotateValue = 0;
      this.#visualRotation = 0;
      if (this.hasPreviewImgTarget) this.previewImgTarget.style.transform = "";
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
