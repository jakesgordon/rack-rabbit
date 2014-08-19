require_relative '../test_case'

require 'rack-rabbit/message'

module RackRabbit
  class TestMessage < TestCase

    #--------------------------------------------------------------------------

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

    attr_reader :rabbit

    def setup
      @rabbit = Minitest::Mock.new
    end

    def teardown
      @rabbit.verify
    end

    #--------------------------------------------------------------------------

    def test_default_message

      message = Message.new(rabbit, DELIVERY_TAG, build_properties, BODY)

      assert_equal(DELIVERY_TAG, message.delivery_tag)
      assert_equal(nil,          message.reply_to)
      assert_equal(nil,          message.correlation_id)
      assert_equal(BODY,         message.body)
      assert_equal(:GET,         message.method)
      assert_equal("",           message.uri)
      assert_equal(nil,          message.status)
      assert_equal(nil,          message.path)
      assert_equal(nil,          message.query)
      assert_equal(nil,          message.content_type)
      assert_equal(nil,          message.content_encoding)
      assert_equal(BODY.length,  message.content_length)
      assert_equal(false,        message.should_reply?)
      assert_equal(false,        message.acknowledged?)
      assert_equal(false,        message.rejected?)
      assert_equal(false,        message.confirmed?)

    end

    #--------------------------------------------------------------------------

    def test_populated_message

      properties = build_properties({
        :reply_to         => REPLY_TO,
        :correlation_id   => CORRELATION_ID,
        :content_type     => CONTENT_TYPE,
        :content_encoding => CONTENT_ENCODING,
        :headers          => {
          RackRabbit::HEADER::METHOD => :POST,
          RackRabbit::HEADER::PATH   => URI,
          RackRabbit::HEADER::STATUS => 200,
          :foo                       => "bar",
        }
      })

      message = Message.new(rabbit, DELIVERY_TAG, properties, BODY)

      assert_equal(DELIVERY_TAG,     message.delivery_tag)
      assert_equal(REPLY_TO,         message.reply_to)
      assert_equal(CORRELATION_ID,   message.correlation_id)
      assert_equal(BODY,             message.body)
      assert_equal(:POST,            message.method)
      assert_equal(URI,              message.uri)
      assert_equal(200,              message.status)
      assert_equal(PATH,             message.path)
      assert_equal(QUERY,            message.query)
      assert_equal(CONTENT_TYPE,     message.content_type)
      assert_equal(CONTENT_ENCODING, message.content_encoding)
      assert_equal(BODY.length,      message.content_length)
      assert_equal(true,             message.should_reply?)
      assert_equal(false,            message.acknowledged?)
      assert_equal(false,            message.rejected?)
      assert_equal(false,            message.confirmed?)

    end

    #--------------------------------------------------------------------------

    def test_should_reply?
      m1 = Message.new(rabbit, DELIVERY_TAG, build_properties(:reply_to => nil),      BODY)
      m2 = Message.new(rabbit, DELIVERY_TAG, build_properties(:reply_to => REPLY_TO), BODY)
      assert_equal(false, m1.should_reply?)
      assert_equal(true,  m2.should_reply?)
    end

    #--------------------------------------------------------------------------

    def test_ack

      rabbit.expect(:ack, nil, [ DELIVERY_TAG ])

      message = Message.new(rabbit, DELIVERY_TAG, build_properties, BODY)
      assert_equal(false, message.acknowledged?)
      assert_equal(false, message.rejected?)
      assert_equal(false, message.confirmed?)

      message.ack
      assert_equal(true,  message.acknowledged?)
      assert_equal(false, message.rejected?)
      assert_equal(true,  message.confirmed?)

    end

    #--------------------------------------------------------------------------

    def test_reject

      rabbit.expect(:reject, nil, [ DELIVERY_TAG, false ])

      message = Message.new(rabbit, DELIVERY_TAG, build_properties, BODY)
      assert_equal(false, message.acknowledged?)
      assert_equal(false, message.rejected?)
      assert_equal(false, message.confirmed?)

      message.reject

      assert_equal(false, message.acknowledged?)
      assert_equal(true,  message.rejected?)
      assert_equal(true,  message.confirmed?)

    end

    #--------------------------------------------------------------------------

    def test_reject_with_requeue

      rabbit.expect(:reject, nil, [ DELIVERY_TAG, true ])

      message = Message.new(rabbit, DELIVERY_TAG, build_properties, BODY)
      assert_equal(false, message.acknowledged?)
      assert_equal(false, message.rejected?)
      assert_equal(false, message.confirmed?)

      message.reject(true)

      assert_equal(false, message.acknowledged?)
      assert_equal(true,  message.rejected?)
      assert_equal(true,  message.confirmed?)

    end

    #--------------------------------------------------------------------------

    private

    def build_properties(options = {})
      return OpenStruct.new(options)
    end

    #--------------------------------------------------------------------------

  end # class TestMessage
end # module RackRabbit

