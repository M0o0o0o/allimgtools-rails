import ImageToolController from "lib/image_tool_controller";

export default class extends ImageToolController {
  static targets = ["qualitySlider", "qualityDisplay", "stripExifCheckbox"];

  static values = {
    quality: { type: Number, default: 80 },
  };

  get processingStatusText() {
    return "Starting compression...";
  }

  buildFormData(formData) {
    formData.append("quality", this.qualityValue);
    const stripExif = this.stripExifCheckboxTargets.some((el) => el.checked);
    formData.append("strip_exif", stripExif);
  }

  // ── Settings ────────────────────────────────────────────────────

  updateQuality(event) {
    this.qualityValue = parseInt(event.target.value);
  }

  qualityValueChanged(value) {
    this.qualityDisplayTargets.forEach((el) => (el.textContent = value));
    this.qualitySliderTargets.forEach((el) => (el.value = value));
  }

  // ── Start ────────────────────────────────────────────────────────

  startCompression() {
    this.startTool();
  }
}
