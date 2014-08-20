require_relative '../test_case'

require 'rack-rabbit/message'

module RackRabbit
  class TestMessage < TestCase

    #--------------------------------------------------------------------------

    include MocksRabbit

    #--------------------------------------------------------------------------

    def test_default_message

      message = build_message

      assert_equal(nil,   message.delivery_tag)
      assert_equal(nil,   message.reply_to)
      assert_equal(nil,   message.correlation_id)
      assert_equal(nil,   message.body)
      assert_equal(:GET,  message.method)
      assert_equal("",    message.uri)
      assert_equal(nil,   message.status)
      assert_equal(nil,   message.path)
      assert_equal(nil,   message.query)
      assert_equal(nil,   message.content_type)
      assert_equal(nil,   message.content_encoding)
      assert_equal(0,     message.content_length)
      assert_equal(false, message.should_reply?)
      assert_equal(false, message.acknowledged?)
      assert_equal(false, message.rejected?)
      assert_equal(false, message.confirmed?)

    end

    #--------------------------------------------------------------------------

    def test_populated_message

      message = build_message({
        :delivery_tag     => DELIVERY_TAG,
        :reply_to         => REPLY_TO,
        :correlation_id   => CORRELATION_ID,
        :content_type     => CONTENT_TYPE,
        :content_encoding => CONTENT_ENCODING,
        :headers          => {
          RackRabbit::HEADER::METHOD => :POST,
          RackRabbit::HEADER::PATH   => URI,
          RackRabbit::HEADER::STATUS => 200,
          :foo                       => "bar",
        },
        :body => BODY
      })

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
      m1 = build_message(:reply_to => nil)
      m2 = build_message(:reply_to => REPLY_TO)
      assert_equal(false, m1.should_reply?)
      assert_equal(true,  m2.should_reply?)
    end

    #--------------------------------------------------------------------------

    def test_ack

      message = build_message(:delivery_tag => DELIVERY_TAG)
      assert_equal(false, message.acknowledged?)
      assert_equal(false, message.rejected?)
      assert_equal(false, message.confirmed?)

      message.ack
      assert_equal(true,  message.acknowledged?)
      assert_equal(false, message.rejected?)
      assert_equal(true,  message.confirmed?)

      assert_equal([DELIVERY_TAG], rabbit.acked_messages)
      assert_equal([],             rabbit.rejected_messages)
      assert_equal([],             rabbit.requeued_messages)

    end

    #--------------------------------------------------------------------------

    def test_reject

      message = build_message(:delivery_tag => DELIVERY_TAG)
      assert_equal(false, message.acknowledged?)
      assert_equal(false, message.rejected?)
      assert_equal(false, message.confirmed?)

      message.reject

      assert_equal(false, message.acknowledged?)
      assert_equal(true,  message.rejected?)
      assert_equal(true,  message.confirmed?)

      assert_equal([],             rabbit.acked_messages)
      assert_equal([DELIVERY_TAG], rabbit.rejected_messages)
      assert_equal([],             rabbit.requeued_messages)

    end

    #--------------------------------------------------------------------------

    def test_reject_with_requeue

      message = build_message(:delivery_tag => DELIVERY_TAG)
      assert_equal(false, message.acknowledged?)
      assert_equal(false, message.rejected?)
      assert_equal(false, message.confirmed?)

      message.reject(true)

      assert_equal(false, message.acknowledged?)
      assert_equal(true,  message.rejected?)
      assert_equal(true,  message.confirmed?)

      assert_equal([],             rabbit.acked_messages)
      assert_equal([],             rabbit.rejected_messages)
      assert_equal([DELIVERY_TAG], rabbit.requeued_messages)

    end

    #--------------------------------------------------------------------------

  end # class TestMessage
end # module RackRabbit

