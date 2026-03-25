import ImageToolController from "lib/image_tool_controller";

export default class extends ImageToolController {
  get processingStatusText() {
    return "Removing EXIF data...";
  }

  buildFormData(_formData) {}

  startExifRemoval() {
    this.startTool();
  }
}
