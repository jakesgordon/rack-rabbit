require 'minitest/autorun'
require 'ostruct'

require 'rack-rabbit'
require 'rack-rabbit/config'
require 'rack-rabbit/message'
require 'rack-rabbit/server'

module RackRabbit
  class TestCase < Minitest::Unit::TestCase

    #--------------------------------------------------------------------------

    EMPTY_CONFIG     = File.expand_path("examples/empty.conf",  File.dirname(__FILE__))
    SIMPLE_CONFIG    = File.expand_path("examples/simple.conf", File.dirname(__FILE__))

    #--------------------------------------------------------------------------

    DEFAULT_RACK_APP = File.expand_path("examples/config.ru",   File.dirname(__FILE__))
    SIMPLE_RACK_APP  = File.expand_path("examples/simple.ru",   File.dirname(__FILE__))
    EXAMINE_RACK_APP = File.expand_path("examples/examine.ru",  File.dirname(__FILE__))

    #--------------------------------------------------------------------------

    APP_ID           = "app.id"
    DELIVERY_TAG     = "delivery.tag"
    REPLY_TO         = "reply.queue"
    CORRELATION_ID   = "correlation.id"
    CONTENT_TYPE     = "text/plain; charset = \"utf-8\""
    CONTENT_ENCODING = "utf-8"
    BODY             = "body"
    PATH             = "/foo/bar"
    QUERY            = "a=b&c=d"
    URI              = "#{PATH}?#{QUERY}"

    #--------------------------------------------------------------------------

    module MocksRabbit

      def self.included(base)
        attr_accessor :rabbit
      end

      def before_setup
        super
        @rabbit = Minitest::Mock.new
      end

      def after_teardown
        super
        @rabbit.verify
      end

    end

    #--------------------------------------------------------------------------

    def build_config(options = {})
      Config.new({ :rack_file => DEFAULT_RACK_APP }.merge(options))
    end

    def build_server(options = {})
      Server.new({ :rack_file => DEFAULT_RACK_APP }.merge(options))
    end

    def build_rabbit_properties(options = {})
      OpenStruct.new(options)
    end

    def build_message(options = {})
      Message.new(rabbit, options[:delivery_tag], build_rabbit_properties(options), options[:body])
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

  end
end
