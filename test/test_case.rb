require 'minitest/autorun'
require 'mocha/mini_test'
require 'rack'
require 'rack/builder'
require 'ostruct'
require 'timecop'
require 'pp'

require 'rack-rabbit'
require 'rack-rabbit/config'
require 'rack-rabbit/message'
require 'rack-rabbit/response'

module RackRabbit
  class TestCase < Minitest::Unit::TestCase

    #--------------------------------------------------------------------------

    EMPTY_CONFIG     = File.expand_path("apps/empty.conf",  File.dirname(__FILE__))
    CUSTOM_CONFIG    = File.expand_path("apps/custom.conf", File.dirname(__FILE__))

    #--------------------------------------------------------------------------

    DEFAULT_RACK_APP = File.expand_path("apps/config.ru",  File.dirname(__FILE__))
    CUSTOM_RACK_APP  = File.expand_path("apps/custom.ru",  File.dirname(__FILE__))
    ERROR_RACK_APP   = File.expand_path("apps/error.ru",   File.dirname(__FILE__))
    MIRROR_RACK_APP  = File.expand_path("apps/mirror.ru",  File.dirname(__FILE__))

    #--------------------------------------------------------------------------

    APP_ID           = "app.id"
    DELIVERY_TAG     = "delivery.tag"
    REPLY_TO         = "reply.queue"
    CORRELATION_ID   = "correlation.id"
    QUEUE            = "my.queue"
    EXCHANGE         = "my.exchange"
    ROUTE            = "my.route"
    CONTENT_TYPE     = "text/plain; charset = \"utf-8\""
    CONTENT_ENCODING = "utf-8"
    BODY             = "body"
    PATH             = "/foo/bar"
    QUERY            = "a=b&c=d"
    URI              = "#{PATH}?#{QUERY}"

    #--------------------------------------------------------------------------

    NullLogger = Rack::NullLogger.new($stdout)

    #--------------------------------------------------------------------------

    def default_config
      build_config( :rabbit => nil, :logger => nil )   # special case for select tests that want TRUE defaults (not the :mock adapter or NullLogger needed in 80% of other tests)
    end

    def build_config(options = {})
      Config.new({
        :validate  => false,                   # skip validation for most tests
        :rack_file => DEFAULT_RACK_APP,        # required - so default to sample app
        :rabbit    => { :adapter => :mock },   # use RackRabbit::Adapter::Mock to mock out rabbit MQ
        :logger    => NullLogger               # suppress logging during tests
      }.merge(options))
    end

    def build_message(options = {})
      options[:headers] ||= {}
      options[:headers][RackRabbit::HEADER::METHOD] ||= options.delete(:method)  # convenience to make calling code a little more compact
      options[:headers][RackRabbit::HEADER::PATH]   ||= options.delete(:path)    # (ditto)
      options[:headers][RackRabbit::HEADER::STATUS] ||= options.delete(:status)  # (ditto)
      Message.new(options[:delivery_tag], OpenStruct.new(options), options[:body])
    end

    def build_response(status, headers, body)
      Response.new(status, headers, body)
    end

    def build_app(rack_file)
      Rack::Builder.parse_file(rack_file)[0]
    end

    #--------------------------------------------------------------------------

    def assert_raises_argument_error(message = nil, &block)
      e = assert_raises(ArgumentError, &block)
      assert_match(/#{message}/, e.message) unless message.nil?
    end

    #--------------------------------------------------------------------------

    def measure
      start  = Time.now
      yield
      finish = Time.now
      finish - start
    end

    #--------------------------------------------------------------------------

    def with_program_name(name)
      original = $PROGRAM_NAME
      $PROGRAM_NAME = name
      yield
    ensure
      $PROGRAM_NAME = original
    end

    #--------------------------------------------------------------------------

  end
end
