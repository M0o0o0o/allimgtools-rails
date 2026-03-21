import ImageToolController from "lib/image_tool_controller";

export default class extends ImageToolController {
  static targets = ["widthInput", "heightInput", "maintainAspectRatioInput"];

  static values = {
    width: { type: Number, default: 0 },
    height: { type: Number, default: 0 },
    maintainAspectRatio: { type: Boolean, default: true },
  };

  get processingStatusText() {
    return "Starting resize...";
  }

  buildFormData(formData) {
    if (this.widthValue) formData.append("width", this.widthValue);
    if (this.heightValue) formData.append("height", this.heightValue);
    formData.append(
      "maintain_aspect_ratio",
      this.maintainAspectRatioValue ? "true" : "false"
    );
  }

  // ── Settings ────────────────────────────────────────────────────

  updateWidth(event) {
    this.widthValue = parseInt(event.target.value) || 0;
  }

  updateHeight(event) {
    this.heightValue = parseInt(event.target.value) || 0;
  }

  updateMaintainAspectRatio(event) {
    this.maintainAspectRatioValue = event.target.checked;
  }

  widthValueChanged(value) {
    this.widthInputTargets.forEach((el) => (el.value = value || ""));
  }

  heightValueChanged(value) {
    this.heightInputTargets.forEach((el) => (el.value = value || ""));
  }

  maintainAspectRatioValueChanged(value) {
    this.maintainAspectRatioInputTargets.forEach((el) => (el.checked = value));
  }

  // ── Start ────────────────────────────────────────────────────────

  startResize() {
    this.startTool();
  }
}
