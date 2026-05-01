import { Controller } from "@hotwired/stimulus";
import { uploadFiles } from "lib/chunk_uploader";
import { showToast } from "lib/toast";

const CATEGORY_PATTERNS = [
  { key: "datetime",    test: t => /^(DateTimeOriginal|DateTime|DateTimeDigitized|CreateDate|ModifyDate|GPSDateTime|GPSDateStamp|GPSTimeStamp)$/.test(t) },
  { key: "location",    test: t => /^GPS/.test(t) },
  { key: "author",      test: t => /^(Artist|Creator|By-line|ByLine|ByLineTitle|Credit|Source|Copyright|CopyrightNotice|Rights|AuthorsPosition|CopyrightFlag|Licensor)$/.test(t) },
  { key: "description", test: t => /^(Title|Description|ImageDescription|Caption-Abstract|Keywords|Headline|ObjectName|Subject|Caption|Abstract|SpecialInstructions)$/.test(t) },
  { key: "camera",      test: t => /^(Make|Model|Software|LensModel|LensMake|LensID|SerialNumber|CameraSerialNumber|FirmwareVersion|BodySerialNumber)$/.test(t) },
  { key: "exposure",    test: t => /^(ExposureTime|FNumber|ISO|ISOSpeedRatings|Flash|WhiteBalance|ExposureMode|ExposureProgram|FocalLength|ApertureValue|ShutterSpeedValue|ExposureBiasValue|BrightnessValue|MaxApertureValue|FocalLengthIn35mmFilm|DigitalZoomRatio|SceneCaptureType|Orientation)$/.test(t) },
];

const CATEGORY_ORDER = ["datetime", "location", "author", "description", "camera", "exposure", "other"];

function categorizeTag(tag) {
  const cat = CATEGORY_PATTERNS.find(c => c.test(tag));
  return cat ? cat.key : "other";
}

export default class extends Controller {
  static targets = [
    "input", "dropzone", "dropzoneArea", "contentArea",
    "imageList", "editorPanel", "editorPlaceholder",
    "dragOverlay",
  ];

  static values = {
    taskId: String,
    startUrl: String,
    readUrl: String,
    maxFileSize: { type: Number, default: 10 * 1024 * 1024 },
    maxFiles: { type: Number, default: 10 },
    i18n: Object,
  };

  #files = [];
  #uploadIds = new Map();   // File → uploadId
  #pendingUploads = 0;
  #state = "idle";
  #dragCounter = 0;
  #edits = {};              // { uploadId: { tag: value } }
  #originalExif = {};       // { uploadId: { tag: originalValue } }
  #selectedUploadId = null;

  connect() {
    this.#setState("idle");
  }

  // ── File picking ─────────────────────────────────────────────────

  openFilePicker() {
    if (this.#state === "processing") return;
    this.inputTarget.click();
  }

  onFileChange() {
    const files = Array.from(this.inputTarget.files);
    this.inputTarget.value = "";
    this.#handleNewFiles(files);
  }

  onDragEnter(e) {
    e.preventDefault();
    this.#dragCounter++;
    if (this.#state === "idle") {
      this.dropzoneTarget.classList.add("border-primary", "bg-primary/10");
    } else {
      this.dragOverlayTarget.classList.remove("hidden");
    }
  }

  onDragOver(e) { e.preventDefault(); }

  onDragLeave() {
    if (--this.#dragCounter === 0) this.#hideDragFeedback();
  }

  onDrop(e) {
    e.preventDefault();
    this.#dragCounter = 0;
    this.#hideDragFeedback();
    this.#handleNewFiles(Array.from(e.dataTransfer.files));
  }

  #hideDragFeedback() {
    this.dropzoneTarget.classList.remove("border-primary", "bg-primary/10");
    this.dragOverlayTarget.classList.add("hidden");
  }

  #handleNewFiles(files) {
    if (this.#state === "processing") return;

    const maxSize  = this.maxFileSizeValue;
    const maxFiles = this.maxFilesValue;
    const limitMB  = Math.round(maxSize / (1024 * 1024));

    const oversized = files.filter(f => f.size > maxSize);
    if (oversized.length) {
      showToast(`${oversized.map(f => f.name).join(", ")} exceed${oversized.length === 1 ? "s" : ""} the ${limitMB}MB limit.`, "warning");
    }

    let valid = files.filter(f => f.size <= maxSize);
    const remaining = maxFiles - this.#files.length;

    if (remaining <= 0) {
      showToast(`You can upload up to ${maxFiles} files at once.`, "warning");
      return;
    }
    if (valid.length > remaining) {
      showToast(`Only ${remaining} more file${remaining !== 1 ? "s" : ""} allowed (limit: ${maxFiles}).`, "warning");
      valid = valid.slice(0, remaining);
    }
    if (!valid.length) return;

    this.#files = [...this.#files, ...valid];
    this.#setState("uploading");
    this.#renderImageList();
    this.#uploadFiles(valid);
  }

  // ── Upload ───────────────────────────────────────────────────────

  async #uploadFiles(files) {
    this.#pendingUploads += files.length;

    await uploadFiles(files, this.taskIdValue, {
      onSuccess: async (file, uploadId) => {
        this.#uploadIds.set(file, uploadId);
        this.#edits[uploadId] = {};
        this.#originalExif[uploadId] = {};
        this.#renderImageList();
        await this.#fetchExif(file, uploadId);
      },
      onError: (file, err) => {
        showToast(`Failed to upload ${file.name}: ${err.message}`);
        this.#files = this.#files.filter(f => f !== file);
        this.#renderImageList();
      },
      onFileSettled: () => {
        this.#pendingUploads--;
        if (this.#pendingUploads === 0) {
          this.#setState(this.#files.length ? "ready" : "idle");
        }
      },
    });
  }

  async #fetchExif(file, uploadId) {
    try {
      const url = `${this.readUrlValue}?upload_id=${encodeURIComponent(uploadId)}`;
      const res  = await fetch(url, { headers: { Accept: "application/json" } });
      const data = await res.json();
      const exif = data.exif || {};
      this.#originalExif[uploadId] = exif;
      this.#edits[uploadId] = { ...exif };
      if (this.#selectedUploadId === uploadId) this.#renderEditor(uploadId);
      this.#renderImageList();
    } catch (_) {
      // silently ignore — user can still see the empty state
    }
  }

  // ── Image list (left sidebar) ────────────────────────────────────

  #renderImageList() {
    const list = this.imageListTarget;
    list.innerHTML = "";

    this.#files.forEach(file => {
      const uploadId    = this.#uploadIds.get(file);
      const isSelected  = uploadId && uploadId === this.#selectedUploadId;
      const isEdited    = uploadId && this.#hasEdits(uploadId);
      const isUploading = !uploadId;

      const li = document.createElement("li");
      li.className = [
        // Mobile: compact vertical card (thumb + label), fixed width for horizontal strip
        // Desktop: horizontal row filling sidebar width
        "flex flex-col lg:flex-row items-center gap-1 lg:gap-3",
        "p-1.5 lg:px-3 lg:py-2.5 rounded-xl cursor-pointer transition-colors group",
        "w-16 shrink-0 lg:w-auto lg:shrink",
        isSelected ? "bg-primary/10 text-primary" : "hover:bg-base-200",
      ].join(" ");
      if (uploadId) li.addEventListener("click", () => this.#selectImage(uploadId));

      // Thumbnail — slightly larger on mobile since it carries most visual weight
      const thumb = document.createElement("div");
      thumb.className = "w-12 h-12 lg:w-10 lg:h-10 rounded-lg overflow-hidden bg-base-200 shrink-0 relative";
      const img = document.createElement("img");
      img.className = "w-full h-full object-cover";
      img.src = URL.createObjectURL(file);
      img.onload = () => URL.revokeObjectURL(img.src);
      thumb.appendChild(img);

      if (isUploading) {
        const overlay = document.createElement("div");
        overlay.className = "absolute inset-0 bg-base-100/70 flex items-center justify-center";
        overlay.innerHTML = `<span class="loading loading-spinner loading-xs text-primary"></span>`;
        thumb.appendChild(overlay);
      }

      // Edited dot indicator — mobile only (shown as a badge on the thumbnail corner)
      if (isEdited) {
        const dot = document.createElement("div");
        dot.className = "absolute top-0.5 right-0.5 w-2.5 h-2.5 rounded-full bg-primary border-2 border-base-100 lg:hidden";
        thumb.appendChild(dot);
      }

      // Mobile filename label — truncated, below thumbnail
      const mobileLabel = document.createElement("p");
      mobileLabel.className = [
        "lg:hidden text-center truncate w-full leading-tight",
        "text-xs",
        isSelected ? "text-primary font-semibold" : "text-base-content/60",
      ].join(" ");
      mobileLabel.style.maxWidth = "60px";
      mobileLabel.textContent = file.name.replace(/\.[^.]+$/, "");

      // Desktop info (filename + edited badge) — hidden on mobile
      const info = document.createElement("div");
      info.className = "hidden lg:flex flex-1 min-w-0 flex-col";
      const nameEl = document.createElement("p");
      nameEl.className = `text-sm font-medium truncate ${isSelected ? "text-primary" : ""}`;
      nameEl.textContent = file.name;
      info.appendChild(nameEl);

      if (isEdited) {
        const badge = document.createElement("span");
        badge.className = "text-xs text-primary font-semibold";
        badge.textContent = this.i18nValue.edited_badge || "Edited";
        info.appendChild(badge);
      }

      // Remove button — desktop only (long list is manageable; mobile strip is compact)
      const removeBtn = document.createElement("button");
      removeBtn.type = "button";
      removeBtn.className = "hidden lg:inline-flex btn btn-ghost btn-xs btn-circle opacity-0 group-hover:opacity-100 shrink-0 text-base-content/40 hover:text-error";
      removeBtn.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M6 18L18 6M6 6l12 12"/></svg>`;
      removeBtn.addEventListener("click", e => { e.stopPropagation(); this.#removeFile(file); });

      li.append(thumb, mobileLabel, info, removeBtn);
      list.appendChild(li);
    });
  }

  #removeFile(file) {
    const uploadId = this.#uploadIds.get(file);
    if (uploadId) {
      delete this.#edits[uploadId];
      delete this.#originalExif[uploadId];
      this.#uploadIds.delete(file);
      if (this.#selectedUploadId === uploadId) {
        this.#selectedUploadId = null;
        this.#showPlaceholder();
      }
    }
    this.#files = this.#files.filter(f => f !== file);
    if (!this.#files.length) {
      this.#setState("idle");
    } else {
      this.#renderImageList();
    }
  }

  #hasEdits(uploadId) {
    const orig  = this.#originalExif[uploadId] || {};
    const edits = this.#edits[uploadId] || {};
    return Object.keys(edits).some(k => (edits[k] ?? "") !== (orig[k] ?? ""));
  }

  // ── Editor panel (right) ─────────────────────────────────────────

  #selectImage(uploadId) {
    this.#selectedUploadId = uploadId;
    this.#renderImageList();
    this.#renderEditor(uploadId);
    // On mobile, scroll the editor into view so the user sees it update
    if (window.innerWidth < 1024) {
      const scrollEl = this.editorPanelTarget.closest(".overflow-y-auto");
      if (scrollEl) scrollEl.scrollTo({ top: 0, behavior: "smooth" });
    }
  }

  #showPlaceholder() {
    this.editorPlaceholderTarget.classList.remove("hidden");
    this.editorPanelTarget.innerHTML = "";
  }

  #renderEditor(uploadId) {
    this.editorPlaceholderTarget.classList.add("hidden");
    const panel = this.editorPanelTarget;
    panel.innerHTML = "";

    const edits = this.#edits[uploadId] || {};
    const i18n  = this.i18nValue;
    const tags   = Object.keys(edits);

    if (tags.length === 0) {
      const msg = document.createElement("p");
      msg.className = "text-sm text-base-content/40 text-center py-8";
      msg.textContent = i18n.no_exif || "No readable metadata found in this image.";
      panel.appendChild(msg);
      return;
    }

    // Apply-to-all button
    const applyAllBtn = document.createElement("button");
    applyAllBtn.type = "button";
    applyAllBtn.className = "btn btn-outline btn-sm w-full mb-5";
    applyAllBtn.textContent = i18n.apply_all || "Apply to all images";
    applyAllBtn.addEventListener("click", () => this.#applyToAll(uploadId));
    panel.appendChild(applyAllBtn);

    // Group tags by category
    const grouped = {};
    CATEGORY_ORDER.forEach(k => { grouped[k] = []; });
    tags.forEach(tag => grouped[categorizeTag(tag)].push(tag));

    // Render each non-empty category
    CATEGORY_ORDER.forEach(catKey => {
      const catTags = grouped[catKey].sort();
      if (!catTags.length) return;

      const wrap = document.createElement("div");
      wrap.className = "mb-6";

      const heading = document.createElement("h3");
      heading.className = "text-xs font-bold uppercase tracking-wider text-base-content/40 mb-3 pb-1 border-b border-base-200";
      heading.textContent = i18n[`section_${catKey}`] || catKey;
      wrap.appendChild(heading);

      catTags.forEach(tag => {
        wrap.appendChild(this.#buildFieldEl(uploadId, tag, edits[tag]));
      });

      panel.appendChild(wrap);
    });
  }

  #buildFieldEl(uploadId, field, currentValue) {
    const i18n      = this.i18nValue;
    const isGps     = field.startsWith("GPS");
    const isDatetime = /^(DateTimeOriginal|DateTime|DateTimeDigitized|CreateDate|ModifyDate)$/.test(field);

    const wrapper = document.createElement("div");
    wrapper.className = "mb-3";

    const label = document.createElement("label");
    label.className = "block text-xs font-semibold text-base-content/60 mb-1";
    label.textContent = i18n[`field_${field}`] || field;
    wrapper.appendChild(label);

    const row = document.createElement("div");
    row.className = "flex gap-1.5 items-center";

    const input = document.createElement("input");
    input.type = "text";
    input.className = "input input-bordered input-sm flex-1 font-mono text-sm";
    input.value = currentValue ?? "";
    input.placeholder = isGps
      ? (i18n.gps_hint || "e.g. 37.5665")
      : isDatetime
        ? (i18n.datetime_hint || "YYYY:MM:DD HH:MM:SS")
        : field === "Keywords"
          ? (i18n.keywords_hint || "Separate with commas")
          : "";

    input.addEventListener("input", () => {
      this.#edits[uploadId] ??= {};
      this.#edits[uploadId][field] = input.value;
      this.#renderImageList();
    });

    const clearBtn = document.createElement("button");
    clearBtn.type = "button";
    clearBtn.className = "btn btn-ghost btn-xs btn-circle text-base-content/30 hover:text-error";
    clearBtn.title = i18n.clear_field || "Clear";
    clearBtn.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M6 18L18 6M6 6l12 12"/></svg>`;
    clearBtn.addEventListener("click", () => {
      input.value = "";
      this.#edits[uploadId] ??= {};
      this.#edits[uploadId][field] = "";
      this.#renderImageList();
    });

    row.append(input, clearBtn);
    wrapper.appendChild(row);
    return wrapper;
  }

  #applyToAll(sourceUploadId) {
    const i18n = this.i18nValue;
    if (!confirm(i18n.apply_all_confirm || "Apply these values to all images?")) return;
    const source = this.#edits[sourceUploadId] || {};
    this.#uploadIds.forEach(uid => {
      if (uid !== sourceUploadId) this.#edits[uid] = { ...source };
    });
    this.#renderImageList();
    showToast("Applied to all images.", "success");
  }

  // ── Start / submit ───────────────────────────────────────────────

  async startTool() {
    if (this.#state !== "ready") return;
    this.#setState("processing");

    const csrf = document.querySelector('meta[name="csrf-token"]').content;

    // Only send fields that changed from the original
    const editsPayload = {};
    this.#uploadIds.forEach(uploadId => {
      const orig  = this.#originalExif[uploadId] || {};
      const edits = this.#edits[uploadId] || {};
      const changed = {};

      for (const [field, value] of Object.entries(edits)) {
        if (value !== (orig[field] ?? "")) changed[field] = value;
      }
      // Fields removed via applyToAll (in orig but not in edits)
      for (const field of Object.keys(orig)) {
        if (!(field in edits)) changed[field] = "";
      }

      editsPayload[uploadId] = changed;
    });

    try {
      const formData = new FormData();
      formData.append("task_id", this.taskIdValue);
      formData.append("edits", JSON.stringify(editsPayload));

      const res  = await fetch(this.startUrlValue, {
        method: "POST",
        headers: { "X-CSRF-Token": csrf, Accept: "application/json" },
        body: formData,
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "Failed to start.");
      window.location.href = data.download_url;
    } catch (e) {
      showToast(e.message);
      this.#setState("ready");
    }
  }

  // ── State machine ────────────────────────────────────────────────

  #setState(state) {
    this.#state = state;
    const isIdle       = state === "idle";
    const isProcessing = state === "processing";
    const isReady      = state === "ready";

    this.dropzoneAreaTarget.classList.toggle("hidden", !isIdle);
    this.contentAreaTarget.classList.toggle("hidden", isIdle);

    this.element.querySelectorAll("[data-exif-edit-tool-target='startBtn']").forEach(btn => {
      btn.disabled = !isReady;
    });
    this.element.querySelectorAll("[data-exif-edit-tool-target='fixedActions']").forEach(el => {
      el.classList.toggle("hidden", isIdle);
    });

    if (isProcessing) {
      this.element.querySelectorAll("[data-exif-edit-tool-target='processingOverlay']").forEach(el => {
        el.classList.remove("hidden");
      });
    } else {
      this.element.querySelectorAll("[data-exif-edit-tool-target='processingOverlay']").forEach(el => {
        el.classList.add("hidden");
      });
    }

    if (isIdle) {
      this.#files = [];
      this.#uploadIds.clear();
      this.#edits = {};
      this.#originalExif = {};
      this.#selectedUploadId = null;
      this.#pendingUploads = 0;
      this.#dragCounter = 0;
      this.imageListTarget.innerHTML = "";
      this.editorPanelTarget.innerHTML = "";
      this.editorPlaceholderTarget.classList.remove("hidden");
    }
  }
}
