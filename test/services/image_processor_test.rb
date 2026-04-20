require "test_helper"

class ImageProcessorTest < ActiveSupport::TestCase
  # ── processable? ─────────────────────────────────────────────────────────

  test "processable? returns true for image content type" do
    file = OpenStruct.new(content_type: "image/jpeg")
    assert ImageProcessor.processable?(file)
  end

  test "processable? returns true for image/png" do
    file = OpenStruct.new(content_type: "image/png")
    assert ImageProcessor.processable?(file)
  end

  test "processable? returns false for non-image content type" do
    file = OpenStruct.new(content_type: "application/pdf")
    assert_not ImageProcessor.processable?(file)
  end

  test "processable? returns false for nil content type" do
    file = OpenStruct.new(content_type: nil)
    assert_not ImageProcessor.processable?(file)
  end

  test "processable? returns false for object without content_type" do
    assert_not ImageProcessor.processable?(Object.new)
  end

  # ── normalize_filename ────────────────────────────────────────────────────

  test "normalize_filename lowercases and strips extension" do
    assert_equal "my-photo.webp", ImageProcessor.normalize_filename("My Photo.jpg")
  end

  test "normalize_filename replaces special chars with hyphens" do
    assert_equal "hello-world.webp", ImageProcessor.normalize_filename("hello_world!.png")
  end

  test "normalize_filename removes leading and trailing hyphens" do
    assert_equal "test.webp", ImageProcessor.normalize_filename("__test__.png")
  end

  test "normalize_filename uses 'image' for blank slug" do
    assert_equal "image.webp", ImageProcessor.normalize_filename("_.png")
  end

  test "normalize_filename handles unicode characters" do
    result = ImageProcessor.normalize_filename("café.jpg")
    assert result.end_with?(".webp")
    assert_match(/\A[a-z0-9\-]+\.webp\z/, result)
  end

  # ── process ──────────────────────────────────────────────────────────────

  test "process skips non-processable file and returns original" do
    file = OpenStruct.new(content_type: "application/zip")
    assert_equal file, ImageProcessor.process(file)
  end

  test "process converts image to webp via vips pipeline" do
    tempfile = Tempfile.new(["input", ".png"])
    tempfile.binmode
    tempfile.write(MINIMAL_PNG)
    tempfile.rewind

    uploaded = ActionDispatch::Http::UploadedFile.new(
      tempfile:          tempfile,
      filename:          "test.png",
      type:              "image/png",
      original_filename: "test.png"
    )

    with_vips_stub(content: MINIMAL_PNG, ext: ".webp") do
      result = ImageProcessor.process(uploaded)
      assert_equal "image/webp", result.content_type
      assert result.original_filename.end_with?(".webp")
    end
  ensure
    tempfile&.close
    tempfile&.unlink
  end
end
