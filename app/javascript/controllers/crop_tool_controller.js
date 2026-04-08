import { Controller } from "@hotwired/stimulus";
import { uploadFiles, MAX_FILE_SIZE } from "lib/chunk_uploader";
import { showToast } from "lib/toast";
import Cropper from "cropperjs";

export default class extends Controller {
  static targets = [
    "input",
    "dropzoneArea",
    "contentArea",
    "cropperImg",
    "startBtn",
    "dragOverlay",
    "progressArea",
    "status",
    "aspectBtn",
    "fixedActions",
  ];

  static values = {
    taskId: String,
    startUrl: String,
  };

  #uploadId = null;
  #state = "idle"; // idle | uploading | ready | processing
  #startRequested = false;
  #waitOverlay = null;
  #dragCounter = 0;
  #cropper = null;
  #blobUrl = null;

  connect() {
    this.#setState("idle");
  }

  disconnect() {
    this.#destroyCropper();
    this.#revokeBlobUrl();
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
    this.#destroyCropper();
    this.#revokeBlobUrl();

    // Keep blob URL alive until cropper is destroyed — v2 uses img.src to
    // create an internal <cropper-image src="...">, so revoking early causes it to fail.
    this.#blobUrl = URL.createObjectURL(file);

    const img = this.cropperImgTarget;
    img.src = this.#blobUrl;
    img.onload = () => {
      this.#initCropper();
    };

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
          if (this.#startRequested) this.startCrop();
        }
      },
    });
  }

  // ── Aspect ratio (v2 API) ─────────────────────────────────────────

  setAspectRatio(event) {
    const sel = this.#cropper?.getCropperSelection();
    if (!sel) return;
    const ratio = event.currentTarget.dataset.ratio;

    this.aspectBtnTargets.forEach((btn) => {
      btn.classList.toggle("btn-primary", btn.dataset.ratio === ratio);
      btn.classList.toggle("btn-outline", btn.dataset.ratio !== ratio);
    });

    if (ratio === "free") {
      sel.aspectRatio = NaN;
    } else {
      const [w, h] = ratio.split(":").map(Number);
      sel.aspectRatio = w / h;
    }
  }

  resetImage() {
    this.#setState("idle");
  }

  openSettings() {
    document.getElementById("settings-modal")?.showModal();
  }

  // ── Start ────────────────────────────────────────────────────────

  startCrop() {
    if (this.#state === "uploading") {
      this.#startRequested = true;
      this.#showWaitOverlay();
      return;
    }
    if (this.#state !== "ready") return;
    if (!this.#cropper) return;

    const sel = this.#cropper.getCropperSelection();
    if (!sel || sel.width <= 0 || sel.height <= 0) {
      showToast("Please select a crop area.");
      return;
    }

    // Convert canvas-space selection coords → original image pixel coords.
    // CSS transform-origin is 50% 50%, so with matrix [scaleX,0,0,scaleY,tx,ty]:
    //   canvas_x = scaleX * (px - natW/2) + tx + natW/2
    // Solving for px:
    //   px = (canvas_x - tx - natW/2) / scaleX + natW/2
    // This handles initial state, zoom, and pan correctly.
    const cropperImg = this.#cropper.getCropperImage();
    const [scaleX, , , scaleY, tx, ty] = cropperImg.$matrix;

    const natW = this.cropperImgTarget.naturalWidth;
    const natH = this.cropperImgTarget.naturalHeight;

    const cropX = Math.max(0, Math.round((sel.x - tx - natW / 2) / scaleX + natW / 2));
    const cropY = Math.max(0, Math.round((sel.y - ty - natH / 2) / scaleY + natH / 2));
    const cropW = Math.max(1, Math.min(Math.round(sel.width / scaleX), natW - cropX));
    const cropH = Math.max(1, Math.min(Math.round(sel.height / scaleY), natH - cropY));

    this.#startRequested = false;
    this.#hideWaitOverlay();
    this.#setState("processing");

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
    const formData = new FormData();
    formData.append("task_id", this.taskIdValue);
    formData.append("upload_id", this.#uploadId);
    formData.append("crop_x", cropX);
    formData.append("crop_y", cropY);
    formData.append("crop_width", cropW);
    formData.append("crop_height", cropH);

    fetch(this.startUrlValue, {
      method: "POST",
      headers: { "X-CSRF-Token": csrfToken, Accept: "application/json" },
      body: formData,
    })
      .then((res) => res.json().then((d) => ({ ok: res.ok, data: d })))
      .then(({ ok, data }) => {
        if (!ok) throw new Error(data.error || "Failed to start.");
        window.location.href = data.download_url;
      })
      .catch((e) => {
        showToast(e.message);
        this.#setState("ready");
      });
  }

  // ── Cropper.js v2 ───────────────────────────────────────────────

  #initCropper() {
    this.#destroyCropper();
    // scalable + translatable are required for $center("contain") to work.
    // rotatable/skewable intentionally omitted so the matrix stays [scale,0,0,scale,tx,ty].
    const template = [
      "<cropper-canvas background>",
      "<cropper-image scalable translatable></cropper-image>",
      '<cropper-handle action="select" plain></cropper-handle>',
      '<cropper-selection initial-coverage="0.8" movable resizable>',
      '<cropper-grid role="grid" bordered covered></cropper-grid>',
      "<cropper-crosshair centered></cropper-crosshair>",
      '<cropper-handle action="move" theme-color="rgba(255,255,255,0.35)"></cropper-handle>',
      '<cropper-handle action="n-resize"></cropper-handle>',
      '<cropper-handle action="e-resize"></cropper-handle>',
      '<cropper-handle action="s-resize"></cropper-handle>',
      '<cropper-handle action="w-resize"></cropper-handle>',
      '<cropper-handle action="ne-resize"></cropper-handle>',
      '<cropper-handle action="nw-resize"></cropper-handle>',
      '<cropper-handle action="se-resize"></cropper-handle>',
      '<cropper-handle action="sw-resize"></cropper-handle>',
      "</cropper-selection>",
      "</cropper-canvas>",
    ].join("");
    this.#cropper = new Cropper(this.cropperImgTarget, { template });

    // Confine the selection within the canvas bounds.
    // Cropper.js v2 has no built-in "confined" option, so we intercept the
    // `change` event, clamp the values, and re-issue $change if needed.
    const sel = this.#cropper.getCropperSelection();
    if (sel) {
      sel.addEventListener("change", (event) => {
        const cnv = sel.$canvas;
        if (!cnv) return;
        const { x, y, width, height } = event.detail;
        const maxW = cnv.offsetWidth;
        const maxH = cnv.offsetHeight;
        const cx = Math.max(0, Math.min(x, maxW - width));
        const cy = Math.max(0, Math.min(y, maxH - height));
        const cw = Math.min(width, maxW - cx);
        const ch = Math.min(height, maxH - cy);
        if (cx !== x || cy !== y || cw !== width || ch !== height) {
          event.preventDefault();
          sel.$change(cx, cy, cw, ch);
        }
      });
    }

    // Blob URLs load near-instantly so CropperImage calls $center("contain") before
    // the flex layout resolves — the canvas is still at its CSS min-height (100px).
    // Use ResizeObserver to re-centre only after the canvas has its real dimensions.
    const canvas = this.element.querySelector("cropper-canvas");
    if (!canvas) return;

    const tryCenter = () => {
      const cropperImg = this.#cropper?.getCropperImage();
      if (!cropperImg) return;

      // Wait for the internal <img> inside <cropper-image> to fully load before
      // reading $matrix. If it hasn't loaded yet, getBoundingClientRect() returns
      // 0×0, causing $center("contain") to compute scale=Infinity which breaks
      // the selection size.
      cropperImg.$ready().then(() => {
        // 1. Scale image to fit within the current (full-size) canvas.
        cropperImg.$center("contain");

        // 2. Shrink canvas to the exact rendered image size so the selection
        //    cannot leave the image area (no letterbox).
        const [scale] = cropperImg.$matrix;
        const natW = this.cropperImgTarget.naturalWidth;
        const natH = this.cropperImgTarget.naturalHeight;
        const renderedW = Math.round(natW * scale);
        const renderedH = Math.round(natH * scale);

        canvas.style.width = `${renderedW}px`;
        canvas.style.height = `${renderedH}px`;

        // 3. Re-centre to remove letterbox offset (tx/ty → 0).
        cropperImg.$center("contain");

        // 4. Reset selection to 80 % of the now image-sized canvas.
        const sel = this.#cropper?.getCropperSelection();
        if (sel) {
          const cov = 0.8;
          sel.$change(
            (renderedW * (1 - cov)) / 2,
            (renderedH * (1 - cov)) / 2,
            renderedW * cov,
            renderedH * cov,
          );
        }
      }).catch(() => {});
    };

    if (canvas.offsetHeight > 100) {
      requestAnimationFrame(tryCenter);
      return;
    }

    const ro = new ResizeObserver(() => {
      if (canvas.offsetHeight > 100) {
        ro.disconnect();
        tryCenter();
      }
    });
    ro.observe(canvas);

    // Fallback: centre anyway after 500 ms in case the viewport is very small.
    setTimeout(() => {
      ro.disconnect();
      tryCenter();
    }, 500);
  }

  #destroyCropper() {
    if (this.#cropper) {
      this.#cropper.destroy();
      this.#cropper = null;
    }
  }

  #revokeBlobUrl() {
    if (this.#blobUrl) {
      URL.revokeObjectURL(this.#blobUrl);
      this.#blobUrl = null;
    }
  }

  // ── State ────────────────────────────────────────────────────────

  #setState(state) {
    this.#state = state;
    const isIdle = state === "idle";
    const isProcessing = state === "processing";

    this.dropzoneAreaTarget.classList.toggle("hidden", !isIdle);
    this.contentAreaTarget.classList.toggle("hidden", isIdle);
    this.progressAreaTarget.classList.toggle("hidden", !isProcessing);

    this.fixedActionsTargets.forEach((el) =>
      el.classList.toggle("hidden", isIdle || isProcessing),
    );

    if (isProcessing) {
      this.statusTarget.textContent = "Cropping image...";
    }

    this.startBtnTargets.forEach(
      (btn) => (btn.disabled = isIdle || isProcessing),
    );

    if (isIdle) {
      this.#startRequested = false;
      this.#hideWaitOverlay();
      this.#uploadId = null;
      this.#destroyCropper();
      this.#revokeBlobUrl();
      this.aspectBtnTargets.forEach((btn) => {
        btn.classList.toggle("btn-primary", btn.dataset.ratio === "free");
        btn.classList.toggle("btn-outline", btn.dataset.ratio !== "free");
      });
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
