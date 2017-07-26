require_relative '../test_case'

module RackRabbit
  class TestSubscriber < TestCase

    #--------------------------------------------------------------------------

    def test_subscribe_lifecycle

      subscriber = build_subscriber
      rabbit     = subscriber.rabbit

      assert_equal(false, rabbit.started?)  
      assert_equal(false, rabbit.connected?)

      subscriber.subscribe
      assert_equal(true, rabbit.started?)
      assert_equal(true, rabbit.connected?)

      subscriber.unsubscribe
      assert_equal(false, rabbit.started?)
      assert_equal(false, rabbit.connected?)

    end

    #--------------------------------------------------------------------------

    def test_subscribe_options
      subscriber = build_subscriber({
        queue: QUEUE,
        exchange: EXCHANGE,
        exchange_type: :fanout,
        routing_key: ROUTE,
        ack: true
      })
      rabbit     = subscriber.rabbit
      subscriber.subscribe
      assert_equal({
        queue: QUEUE,
        exchange: EXCHANGE,
        exchange_type: :fanout,
        routing_key: ROUTE,
        manual_ack: true
      }, rabbit.subscribe_options)
    end

    #--------------------------------------------------------------------------

    def test_subscribe_handles_message

      subscriber = build_subscriber(:app_id => APP_ID)
      message    = build_message
      rabbit     = subscriber.rabbit

      prime(subscriber, message)

      assert_equal([], rabbit.subscribed_messages, "preconditions")

      subscriber.subscribe

      assert_equal([message], rabbit.subscribed_messages)
      assert_equal([],        rabbit.published_messages)
      assert_equal([],        rabbit.acked_messages)
      assert_equal([],        rabbit.rejected_messages)

    end

    #--------------------------------------------------------------------------

    def test_handle_message_that_expects_a_reply

      subscriber = build_subscriber(:app_id => APP_ID) 
      message    = build_message(:delivery_tag => DELIVERY_TAG, :reply_to => REPLY_TO, :correlation_id => CORRELATION_ID)
      rabbit     = subscriber.rabbit

      prime(subscriber, message)

      subscriber.subscribe

      assert_equal([message],      rabbit.subscribed_messages)
      assert_equal([],             rabbit.acked_messages)
      assert_equal([],             rabbit.rejected_messages)
      assert_equal(1,              rabbit.published_messages.length)
      assert_equal(APP_ID,         rabbit.published_messages[0][:app_id])
      assert_equal(REPLY_TO,       rabbit.published_messages[0][:routing_key])
      assert_equal(CORRELATION_ID, rabbit.published_messages[0][:correlation_id])
      assert_equal(200,            rabbit.published_messages[0][:headers][RackRabbit::HEADER::STATUS])
      assert_equal("ok",           rabbit.published_messages[0][:body])

    end

    #--------------------------------------------------------------------------

    def test_successful_message_is_acked

      rabbit     = build_rabbit
      subscriber = build_subscriber(:ack => true, :rabbit => rabbit)
      message    = build_message(:delivery_tag => DELIVERY_TAG, :rabbit => rabbit)

      prime(subscriber, message)

      subscriber.subscribe

      assert_equal([message],      rabbit.subscribed_messages)
      assert_equal([],             rabbit.published_messages)
      assert_equal([DELIVERY_TAG], rabbit.acked_messages)
      assert_equal([],             rabbit.rejected_messages)

    end

    #--------------------------------------------------------------------------

    def test_failed_message_is_rejected

      rabbit     = build_rabbit
      subscriber = build_subscriber(:rack_file => ERROR_RACK_APP, :ack => true, :rabbit => rabbit)
      message    = build_message(:delivery_tag => DELIVERY_TAG, :rabbit => rabbit)
      response   = build_response(500, "uh oh")

      prime(subscriber, [message, response])

      subscriber.subscribe

      assert_equal([message],               rabbit.subscribed_messages)
      assert_equal([],                      rabbit.published_messages)
      assert_equal([],                      rabbit.acked_messages)
      assert_equal([DELIVERY_TAG],          rabbit.rejected_messages)

    end

    #==========================================================================
    # PRIVATE IMPLEMTATION HELPERS
    #==========================================================================

    private

    def prime(subscriber, *messages)
      messages.each do |m|
        m, r = m if m.is_a?(Array)
        r ||= build_response(200, "ok")
        subscriber.rabbit.prime(m)
        subscriber.handler.expects(:handle).with(m).returns(r)
      end
    end

    #--------------------------------------------------------------------------


  end # class TestSubscriber
end # module RackRabbit

