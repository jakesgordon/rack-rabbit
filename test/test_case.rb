require 'minitest/autorun'
require 'mocha/mini_test'
require 'rack'
require 'rack/builder'
require 'ostruct'
require 'timecop'
require 'pp'

require 'rack-rabbit'                 # top level module

require 'rack-rabbit/subscriber'      # subscribes to rabbit queue/exchange and passes messages on to a handler
require 'rack-rabbit/handler'         # converts rabbit messages to rack environments and calls a rack app to handle the request
require 'rack-rabbit/adapter'         # abstract interface to rabbitMQ
require 'rack-rabbit/message'         # a rabbitMQ message
require 'rack-rabbit/response'        # a rack response

require 'rack-rabbit/client'          # client code for making requests
require 'rack-rabbit/worker'          # worker process
require 'rack-rabbit/server'          # server process
require 'rack-rabbit/config'          # server configuration
require 'rack-rabbit/signals'         # process signal queue

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
    REPLY_QUEUE      = "reply.queue"
    EXCHANGE         = "my.exchange"
    ROUTE            = "my.route"
    BODY             = "body"
    PATH             = "/foo/bar"
    QUERY            = "a=b&c=d"
    URI              = "#{PATH}?#{QUERY}"
    PRIORITY         = 7

    module CONTENT
      ASCII                = "iso-8859-1"
      UTF8                 = "utf-8"
      PLAIN_TEXT           = "text/plain"
      PLAIN_TEXT_UTF8      = "text/plain; charset=\"utf-8\""
      FORM_URLENCODED      = "application/x-www-form-urlencoded"
      FORM_URLENCODED_UTF8 = "application/x-www-form-urlencoded; charset=\"utf-8\""
      JSON                 = "application/json"
      JSON_UTF8            = "application/json; charset=\"utf-8\""
      JSON_ASCII           = "application/json; charset=\"iso-8859-1\""
    end

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

    def build_client(options = {})
      Client.new({ :adapter => :mock }.merge(options))
    end

    def build_message(options = {})
      options[:headers] ||= {}
      options[:headers][RackRabbit::HEADER::METHOD] ||= options.delete(:method)  # convenience to make calling code a little more compact
      options[:headers][RackRabbit::HEADER::PATH]   ||= options.delete(:path)    # (ditto)
      options[:headers][RackRabbit::HEADER::STATUS] ||= options.delete(:status)  # (ditto)
      Message.new(options[:delivery_tag], OpenStruct.new(options), options[:body], options[:rabbit] || build_rabbit)
    end

    def build_response(status, body, headers = {})
      headers ||= {}
      headers[RackRabbit::HEADER::CONTENT_TYPE]     ||= headers.delete(:content_type)     # convenience to make calling code a little more compact
      headers[RackRabbit::HEADER::CONTENT_ENCODING] ||= headers.delete(:content_encoding) # (ditto)
      Response.new(status, headers, body)
    end

    def build_app(rack_file)
      Rack::Builder.parse_file(rack_file)[0]
    end

    def build_handler(options = {})
      config = options[:config] || build_config(options)
      app    = options[:app]    || build_app(config.rack_file)
      Handler.new(app, config)
    end

    def build_subscriber(options = {})
      rabbit  = options[:rabbit]  || build_rabbit(options)
      config  = options[:config]  || build_config(options)
      handler = options[:handler] || build_handler(options.merge(:config => config))
      Subscriber.new(rabbit, handler, Mutex.new, handler.config)
    end

    def build_rabbit(options = {})
      Adapter.load({ :adapter => :mock }.merge(options))
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
