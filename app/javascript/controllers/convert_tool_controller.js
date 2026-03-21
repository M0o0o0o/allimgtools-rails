import ImageToolController from "lib/image_tool_controller";

export default class extends ImageToolController {
  static targets = ["toFormatBtn"];

  static values = {
    toFormat: { type: String, default: "" },
    locked:   { type: Boolean, default: false },
  };

  get processingStatusText() {
    return "Converting...";
  }

  buildFormData(formData) {
    formData.append("to_format", this.toFormatValue);
  }

  // ── Format selection ─────────────────────────────────────────────

  selectFormat(event) {
    if (this.lockedValue) return;
    this.toFormatValue = event.currentTarget.dataset.format;
  }

  toFormatValueChanged(value) {
    this.toFormatBtnTargets.forEach((btn) => {
      const active = btn.dataset.format === value;
      btn.classList.toggle("btn-primary", active);
      btn.classList.toggle("btn-outline", !active);
    });
  }

  // ── Start ────────────────────────────────────────────────────────

  startConvert() {
    this.startTool();
  }
}
