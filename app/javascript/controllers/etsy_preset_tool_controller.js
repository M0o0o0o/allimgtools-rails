import ImageToolController from "lib/image_tool_controller";

export default class extends ImageToolController {
  static targets = ["formatBtn", "qualitySlider", "qualityDisplay", "stripExifCheckbox"];

  static values = {
    format: { type: String, default: "jpeg" },
    quality: { type: Number, default: 85 },
  };

  get processingStatusText() {
    return "Making Etsy-ready...";
  }

  buildFormData(formData) {
    formData.append("to_format", this.formatValue);
    formData.append("quality", this.qualityValue);
    const stripExif = this.stripExifCheckboxTargets.some((el) => el.checked);
    formData.append("strip_exif", stripExif);
  }

  // ── Settings ────────────────────────────────────────────────────

  selectFormat(event) {
    this.formatValue = event.currentTarget.dataset.format;
  }

  formatValueChanged(value) {
    this.formatBtnTargets.forEach((btn) => {
      btn.classList.toggle("btn-primary", btn.dataset.format === value);
      btn.classList.toggle("btn-outline", btn.dataset.format !== value);
    });
  }

  updateQuality(event) {
    this.qualityValue = parseInt(event.target.value);
  }

  qualityValueChanged(value) {
    this.qualityDisplayTargets.forEach((el) => (el.textContent = value));
    this.qualitySliderTargets.forEach((el) => (el.value = value));
  }

  // ── Start ────────────────────────────────────────────────────────

  startEtsyPreset() {
    this.startTool();
  }
}
