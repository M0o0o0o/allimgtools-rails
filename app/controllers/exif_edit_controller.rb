class ExifEditController < ApplicationController
  include ToolController

  EXCLUDED_TAGS = %w[
    SourceFile ExifToolVersion Error Warning
    FileType FileTypeExtension MIMEType FileSize FilePermissions
    FileAccessDate FileModifyDate FileInodeChangeDate FileCreateDate
    Directory FileName ExifByteOrder
    JFIFVersion XMPToolkit
    ThumbnailImage ThumbnailOffset ThumbnailLength ThumbnailTIFF
    PreviewImage PreviewImageLength PreviewImageStart PreviewImageValid
    JpgFromRaw JpgFromRawLength JpgFromRawStart
    MPEntry MPImageLength MPImageStart NumberOfImages
    ImageWidth ImageHeight ImageSize Megapixels ExifImageWidth ExifImageHeight
    BitsPerSample SamplesPerPixel Compression EncodingProcess ColorComponents
    PhotometricInterpretation PlanarConfiguration YCbCrSubSampling YCbCrPositioning
    StripOffsets StripByteCounts RowsPerStrip
    XResolution YResolution ResolutionUnit
    FlashpixVersion ColorSpace ComponentsConfiguration CompressedBitsPerPixel
    InteropIndex InteropVersion RelatedImageWidth RelatedImageLength
    MakerNote SubjectArea CFAPattern CFARepeatPatternDim
    GPSVersionID GPSLatitudeRef GPSLongitudeRef GPSAltitudeRef
    GPSMeasureMode GPSMapDatum GPSDOP GPSSpeedRef GPSTrackRef
    GPSImgDirectionRef GPSDestBearingRef GPSDestDistanceRef GPSStatus
    GPSSpeed GPSTrack GPSImgDirection GPSDestLatitude GPSDestLongitude
    GPSDestBearing GPSDestDistance GPSSatellites GPSProcessingMethod
    GPSAreaInformation GPSDifferential
  ].freeze

  TEMPLATE_FIELDS = %w[
    DateTimeOriginal DateTimeDigitized
    GPSLatitude GPSLongitude GPSAltitude
    Artist Copyright
    ImageDescription Keywords
  ].freeze

  def new
    @task = create_task
  end

  def read
    upload = Upload.completed.find_by!(upload_id: params[:upload_id])

    data = upload.file.open do |f|
      raw = IO.popen([ "exiftool", "-json", "-n", f.path ], &:read)
      tags = JSON.parse(raw).first || {}

      existing = tags.each_with_object({}) do |(key, val), h|
        next if EXCLUDED_TAGS.include?(key)
        next unless val.is_a?(String) || val.is_a?(Numeric) || val.is_a?(Array)
        str = val.is_a?(Array) ? val.map(&:to_s).join(", ") : val.to_s.strip
        next if str.empty?
        h[key] = str
      end

      TEMPLATE_FIELDS.each_with_object(existing) { |field, h| h[field] ||= "" }
    end

    render json: { exif: data }
  rescue
    render json: { exif: {} }
  end

  def start
    task = find_task
    edits = JSON.parse(params[:edits])

    task.update!(status: "processing")
    EditExifJob.perform_later(task.task_id, edits: edits)

    render_download_url(task)
  end
end
