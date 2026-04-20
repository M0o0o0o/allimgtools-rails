ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "base64"

# minitest 6.x removed Object#stub — restore it so tests can use obj.stub(:method, val) { ... }
unless Object.method_defined?(:stub)
  module MinitestStubCompat
    def stub(name, val_or_callable, *block_args, **block_kwargs, &block)
      new_name = :"__stub_#{name}__"
      metaclass = class << self; self; end

      # Ensure the method exists on the metaclass so alias_method works
      unless methods(false).map(&:to_s).include?(name.to_s)
        original_owner = method(name).owner
        metaclass.define_method(name) { |*a, **k, &b| original_owner.instance_method(name).bind_call(self, *a, **k, &b) }
      end

      metaclass.alias_method new_name, name
      metaclass.define_method(name) do |*args, **kwargs, &blk|
        if val_or_callable.respond_to?(:call)
          val_or_callable.call(*args, **kwargs, &blk)
        else
          val_or_callable
        end
      end

      block.call(*block_args, **block_kwargs)
    ensure
      metaclass.undef_method name rescue nil
      metaclass.alias_method name, new_name rescue nil
      metaclass.undef_method new_name rescue nil
    end
  end

  Object.include MinitestStubCompat
end
require "openssl"
require "ostruct"
require_relative "test_helpers/session_test_helper"

# Paddle test ENV – allows PaddleApi.resolve_plan to work without real credentials
ENV["PADDLE_PRO_PRICE_ID"]        ||= "pri_01testmonthly"
ENV["PADDLE_PRO_YEARLY_PRICE_ID"] ||= "pri_01testyearly"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all

    # Minimal 1×1 white PNG (68 bytes) — used as a real image fixture in tests
    MINIMAL_PNG = Base64.decode64(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVQI12NgAAIA" \
      "BQAABjE+ibYAAAAASUVORK5CYII="
    ).freeze

    # ── Task / Upload factories ──────────────────────────────────────────────

    def create_task(tool: "compress", ip: "127.0.0.1")
      Task.create!(task_id: SecureRandom.uuid, tool: tool, ip_address: ip)
    end

    def create_upload(task:, status: "done", filename: "test.png", ip: "127.0.0.1")
      Upload.create!(
        upload_id:    SecureRandom.uuid,
        task_id:      task.task_id,
        filename:     filename,
        total_chunks: 1,
        ip_address:   ip,
        status:       status
      )
    end

    # Attach the minimal PNG to an upload's :file via ActiveStorage (test disk)
    def attach_test_image(upload, filename: "test.png", content_type: "image/png")
      upload.file.attach(
        io:           StringIO.new(MINIMAL_PNG),
        filename:     filename,
        content_type: content_type
      )
    end

    # ── Paddle helpers ───────────────────────────────────────────────────────

    PADDLE_TEST_SECRET    = "test_webhook_secret"
    PADDLE_TEST_API_KEY   = "test_api_key"
    PADDLE_TEST_PRICE_ID  = "pri_01testmonthly"
    PADDLE_TEST_YEARLY_ID = "pri_01testyearly"

    # Paddle credential hash used in stubbed tests
    def paddle_credentials
      {
        webhook_secret: PADDLE_TEST_SECRET,
        api_key:        PADDLE_TEST_API_KEY,
        client_token:   "test_client_token",
        pro_price_id:   PADDLE_TEST_PRICE_ID,
        sandbox:        true
      }
    end

    # Stub Rails.application.credentials to expose paddle: paddle_credentials
    def with_paddle_credentials(overrides = {}, &block)
      creds      = paddle_credentials.merge(overrides)
      creds_obj  = OpenStruct.new(paddle: creds)
      Rails.application.stub(:credentials, creds_obj, &block)
    end

    # Generate a Paddle webhook HMAC signature header
    def paddle_signature(payload, secret: PADDLE_TEST_SECRET, ts: nil)
      ts       ||= Time.current.to_i
      signed     = "#{ts}:#{payload}"
      h1         = OpenSSL::HMAC.hexdigest("SHA256", secret, signed)
      { header: "ts=#{ts};h1=#{h1}", ts: ts }
    end

    # ── ImageProcessing stub ─────────────────────────────────────────────────

    # A chainable object that responds to any vips pipeline message and
    # finally returns `result` on #call. Pass a Tempfile as `result`.
    class ChainablePipelineMock
      def initialize(result)
        @result = result
      end

      def method_missing(_name, *, **, &)
        self
      end

      def respond_to_missing?(_name, _include_private = false)
        true
      end

      def call
        @result
      end
    end

    # Stub ImageProcessing::Vips.source to return a chainable mock whose
    # #call returns a Tempfile containing `content`.
    def with_vips_stub(content: "fake-image-data", ext: ".png")
      result = Tempfile.new(["vips_result", ext])
      result.binmode
      result.write(content)
      result.rewind

      mock = ChainablePipelineMock.new(result)
      ImageProcessing::Vips.stub(:source, mock) do
        yield result
      end
    ensure
      result&.close
      result&.unlink
    end

    # ── Net::HTTP stub ───────────────────────────────────────────────────────

    # Stub Net::HTTP.start to return a mock HTTP response.
    # `body` is converted to JSON automatically.
    def stub_http_response(body:, code: "200", success: true)
      json_body = body.to_json
      mock_res  = Object.new
      mock_res.define_singleton_method(:is_a?) { |klass| klass == Net::HTTPSuccess ? success : false }
      mock_res.define_singleton_method(:body)  { json_body }
      mock_res.define_singleton_method(:code)  { code }

      Net::HTTP.stub(:start, ->(*_args, **_opts, &blk) {
        mock_http = Object.new
        mock_http.define_singleton_method(:request) { |_req| mock_res }
        blk.call(mock_http)
      }) do
        yield mock_res
      end
    end
  end
end
