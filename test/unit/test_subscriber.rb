require_relative '../test_case'

module RackRabbit
  class TestSubscriber < TestCase

    #--------------------------------------------------------------------------

    def test_handle_message

      subscriber = build_subscriber(:app_id => APP_ID) 
      message    = build_message
      rabbit     = subscriber.rabbit

      response = subscriber.handle(message)

      assert_equal(200,             response.status)
      assert_equal("Hello World",   response.body)
      assert_equal([],              rabbit.acked_messages)
      assert_equal([],              rabbit.rejected_messages)
      assert_equal([],              rabbit.requeued_messages)
      assert_equal([],              rabbit.published_messages)

    end

    #--------------------------------------------------------------------------

    def test_handle_message_that_expects_a_reply

      subscriber = build_subscriber(:app_id => APP_ID) 
      message    = build_message(:delivery_tag => DELIVERY_TAG, :reply_to => REPLY_TO, :correlation_id => CORRELATION_ID)
      rabbit     = subscriber.rabbit

      response = subscriber.handle(message)

      assert_equal(200,             response.status)
      assert_equal("Hello World",   response.body)
      assert_equal(1,               rabbit.published_messages.length)
      assert_equal(APP_ID,          rabbit.published_messages[0][:app_id])
      assert_equal(REPLY_TO,        rabbit.published_messages[0][:routing_key])
      assert_equal(CORRELATION_ID,  rabbit.published_messages[0][:correlation_id])
      assert_equal(response.status, rabbit.published_messages[0][:headers][RackRabbit::HEADER::STATUS])
      assert_equal(response.body,   rabbit.published_messages[0][:body])

    end

    #--------------------------------------------------------------------------

    def test_succesful_message_is_acked

      subscriber = build_subscriber(:ack => true)
      message    = build_message(:delivery_tag => DELIVERY_TAG)
      rabbit     = subscriber.rabbit

      response = subscriber.handle(message)

      assert_equal(200,            response.status)
      assert_equal("Hello World",  response.body)
      assert_equal([DELIVERY_TAG], rabbit.acked_messages)
      assert_equal([],             rabbit.rejected_messages)
      assert_equal([],             rabbit.requeued_messages)
      assert_equal([],             rabbit.published_messages)

    end

    #--------------------------------------------------------------------------

    def test_failed_message_is_rejected

      subscriber = build_subscriber(:rack_file => ERROR_RACK_APP, :ack => true)
      message    = build_message(:delivery_tag => DELIVERY_TAG)
      rabbit     = subscriber.rabbit

      response = subscriber.handle(message)

      assert_equal(500,                     response.status)
      assert_equal("Internal Server Error", response.body)
      assert_equal([],                      rabbit.acked_messages)
      assert_equal([DELIVERY_TAG],          rabbit.rejected_messages)
      assert_equal([],                      rabbit.requeued_messages)
      assert_equal([],                      rabbit.published_messages)

    end

    #--------------------------------------------------------------------------

    def test_subscribe

      subscriber = build_subscriber(:queue => QUEUE, :exchange => EXCHANGE, :exchange_type => :fanout, :routing_key => ROUTE, :ack => true)
      rabbit     = subscriber.rabbit

      m1 = build_message(:delivery_tag => "m1")
      m2 = build_message(:delivery_tag => "m2")

      r1 = build_response(200, "r1")
      r2 = build_response(200, "r2")

      rabbit.prime(m1)
      rabbit.prime(m2)

      assert_equal(false, rabbit.started?)  
      assert_equal(false, rabbit.connected?)
      assert_equal(nil,   rabbit.subscribe_options)
      assert_equal([],    rabbit.subscribed_messages)

      subscriber.handler.expects(:handle).with(m1).returns(r1)  # mock out #handle method - it's unit tested separately (above)
      subscriber.handler.expects(:handle).with(m2).returns(r2)  # (ditto)

      subscriber.subscribe

      assert_equal(true, rabbit.started?)
      assert_equal(true, rabbit.connected?)
      assert_equal({:queue => QUEUE, :exchange => EXCHANGE, :exchange_type => :fanout, :routing_key => ROUTE, :ack => true}, rabbit.subscribe_options)
      assert_equal([m1, m2], rabbit.subscribed_messages)

      subscriber.unsubscribe

      assert_equal(false, rabbit.started?)
      assert_equal(false, rabbit.connected?)

    end

    #--------------------------------------------------------------------------

  end # class TestSubscriber
end # module RackRabbit

