require_relative '../test_case'

require 'rack-rabbit/handler'

module RackRabbit
  class TestHandler < TestCase

    #--------------------------------------------------------------------------

    def test_handle_message

      handler = build_handler
      message = build_message

      response = handler.handle(message)

      assert_equal(200,           response.status)
      assert_equal({},            response.headers)
      assert_equal("Hello World", response.body)
      
    end

    #--------------------------------------------------------------------------

    def test_handle_GET

      handler = build_handler(:rack_file => MIRROR_RACK_APP)
      message = build_message(:method => :GET, :path => "/my/path?foo=bar", :body => "hello")

      response = handler.handle(message)
      mirror   = JSON.parse(response.body)

      assert_equal(200,        response.status)
      assert_equal("GET",      mirror["method"])
      assert_equal("/my/path", mirror["path"])
      assert_equal("bar",      mirror["params"]["foo"])
      assert_equal("hello",    mirror["body"])

    end

    #--------------------------------------------------------------------------

    def test_handle_POST

      handler  = build_handler(:rack_file => MIRROR_RACK_APP)
      message  = build_message(:method => :POST, :path => "/my/path?foo=bar", :body => "hello")

      response = handler.handle(message)
      mirror   = JSON.parse(response.body)

      assert_equal(200,        response.status)
      assert_equal("POST",     mirror["method"])
      assert_equal("/my/path", mirror["path"])
      assert_equal("bar",      mirror["params"]["foo"])
      assert_equal("hello",    mirror["body"])

    end

    #--------------------------------------------------------------------------

    def test_handle_POST_form_data

      handler  = build_handler(:rack_file => MIRROR_RACK_APP)
      message  = build_message(:method => :POST, :path => "/my/path", :body => "foo=bar", :content_type => FORM_CONTENT)

      response = handler.handle(message)
      mirror   = JSON.parse(response.body)

      assert_equal(200,        response.status)
      assert_equal("POST",     mirror["method"])
      assert_equal("/my/path", mirror["path"])
      assert_equal("bar",      mirror["params"]["foo"])
      assert_equal("foo=bar",  mirror["body"])

    end

    #--------------------------------------------------------------------------

    def test_handle_message_that_expects_a_reply

      handler = build_handler(:rack_file => DEFAULT_RACK_APP, :app_id => APP_ID)
      message = build_message(:delivery_tag => DELIVERY_TAG, :reply_to => REPLY_TO, :correlation_id => CORRELATION_ID)

      handler.handle(message)

      assert_equal([], handler.rabbit.acked_messages)
      assert_equal([], handler.rabbit.rejected_messages)
      assert_equal([], handler.rabbit.requeued_messages)
      assert_equal(1,  handler.rabbit.published_messages.length)

      reply = handler.rabbit.published_messages[0]

      assert_equal(APP_ID,         reply[:app_id])
      assert_equal(REPLY_TO,       reply[:routing_key])
      assert_equal(CORRELATION_ID, reply[:correlation_id])
      assert_equal(200,            reply[:headers][RackRabbit::HEADER::STATUS])
      assert_equal("Hello World",  reply[:body])

    end

    #--------------------------------------------------------------------------

    def test_handle_message_that_causes_rack_app_to_raise_an_exception

      handler  = build_handler(:rack_file => ERROR_RACK_APP)
      message  = build_message
      response = handler.handle(message)

      assert_equal(500,                     response.status)
      assert_equal("Internal Server Error", response.body)
      assert_equal({},                      response.headers)

      assert_equal([], handler.rabbit.acked_messages)
      assert_equal([], handler.rabbit.rejected_messages)
      assert_equal([], handler.rabbit.requeued_messages)
      assert_equal([], handler.rabbit.published_messages)

    end

    #--------------------------------------------------------------------------

    def test_succesful_message_is_acked

      handler  = build_handler(:rack_file => DEFAULT_RACK_APP, :ack => true)
      message  = build_message(:delivery_tag => DELIVERY_TAG)
      response = handler.handle(message)

      assert_equal(200,            response.status)
      assert_equal("Hello World",  response.body)
      assert_equal([DELIVERY_TAG], handler.rabbit.acked_messages)
      assert_equal([],             handler.rabbit.rejected_messages)
      assert_equal([],             handler.rabbit.requeued_messages)
      assert_equal([],             handler.rabbit.published_messages)

    end

    #--------------------------------------------------------------------------

    def test_failed_message_is_rejected

      handler  = build_handler(:rack_file => ERROR_RACK_APP, :ack => true)
      message  = build_message(:delivery_tag => DELIVERY_TAG)
      response = handler.handle(message)

      assert_equal(500,                     response.status)
      assert_equal("Internal Server Error", response.body)
      assert_equal([],                      handler.rabbit.acked_messages)
      assert_equal([DELIVERY_TAG],          handler.rabbit.rejected_messages)
      assert_equal([],                      handler.rabbit.requeued_messages)
      assert_equal([],                      handler.rabbit.published_messages)

    end

    #--------------------------------------------------------------------------

    def test_rabbit_response_is_generated_correctly_from_rack_response

      handler = build_handler(:rack_file => DEFAULT_RACK_APP, :app_id => APP_ID)

      message = build_message({
        :reply_to         => REPLY_TO,
        :correlation_id   => CORRELATION_ID,
        :content_type     => "request.content.type",
        :content_encoding => "request.content.encoding",
        :method           => "request.method",
        :path             => "request.path",
        :body             => "request.body"
      })

      response = build_response(200, {
        RackRabbit::HEADER::CONTENT_TYPE     => "response.content.type",
        RackRabbit::HEADER::CONTENT_ENCODING => "response.content.encoding",
        :additional => :header
      }, "response.body")

      Timecop.freeze do

        properties = handler.response_properties(message, response)

        assert_equal(APP_ID,                      properties[:app_id])
        assert_equal(REPLY_TO,                    properties[:routing_key])
        assert_equal(CORRELATION_ID,              properties[:correlation_id])
        assert_equal(Time.now.to_i,               properties[:timestamp])
        assert_equal("response.content.type",     properties[:content_type])
        assert_equal("response.content.encoding", properties[:content_encoding])
        assert_equal(:header,                     properties[:headers][:additional])

      end

    end

    #--------------------------------------------------------------------------

    def test_subscribe

      handler = build_handler(:queue => QUEUE, :exchange => EXCHANGE, :exchange_type => :fanout, :routing_key => ROUTE, :ack => true)
      rabbit  = handler.rabbit

      m1 = build_message(:delivery_tag => "m1")
      m2 = build_message(:delivery_tag => "m2")

      r1 = build_response(200, {}, "r1")
      r2 = build_response(200, {}, "r2")

      rabbit.prime(m1)
      rabbit.prime(m2)

      assert_equal(false, rabbit.started?)  
      assert_equal(false, rabbit.connected?)
      assert_equal(nil,   rabbit.subscribe_options)
      assert_equal([],    rabbit.subscribed_messages)

      handler.expects(:handle).with(m1).returns(r1)  # mock out #handle method - it's unit tested separately (above)
      handler.expects(:handle).with(m2).returns(r2)  # (ditto)

      handler.subscribe

      assert_equal(true, rabbit.started?)
      assert_equal(true, rabbit.connected?)
      assert_equal({:queue => QUEUE, :exchange => EXCHANGE, :exchange_type => :fanout, :routing_key => ROUTE, :ack => true}, rabbit.subscribe_options)
      assert_equal([m1, m2], rabbit.subscribed_messages)

      handler.unsubscribe

      assert_equal(false, rabbit.started?)
      assert_equal(false, rabbit.connected?)

    end

    #--------------------------------------------------------------------------

  end # class TestHandler
end # module RackRabbit
