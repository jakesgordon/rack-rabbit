require_relative '../test_case'

module RackRabbit
  class TestClient < TestCase

    #--------------------------------------------------------------------------

    def test_GET

      Timecop.freeze do

        client = build_client
        reply  = build_message(:correlation_id => CORRELATION_ID, :status => 200, :body => "GET OK", :headers => { "additional" => "reply_header" })
        rabbit = client.rabbit

        prime_reply(client, reply)   # prime rabbit with a pending reply message

        response = client.get(QUEUE, "/path", {
          :id               => CORRELATION_ID,    # dependency inject generated message ID
          :priority         => PRIORITY,
          :content_type     => CONTENT::JSON,
          :content_encoding => CONTENT::ASCII,
          :headers          => { "additional" => "request_header" }
        })

        assert_equal(200,            response.status)
        assert_equal("GET OK",       response.body)
        assert_equal("reply_header", response.headers["additional"])

        assert_equal([reply],          rabbit.subscribed_messages)
        assert_equal(1,                rabbit.published_messages.length)
        assert_equal(CORRELATION_ID,   rabbit.published_messages[0][:correlation_id])
        assert_equal(QUEUE,            rabbit.published_messages[0][:routing_key])
        assert_equal(REPLY_QUEUE,      rabbit.published_messages[0][:reply_to])
        assert_equal(PRIORITY,         rabbit.published_messages[0][:priority])
        assert_equal(CONTENT::JSON,    rabbit.published_messages[0][:content_type])
        assert_equal(CONTENT::ASCII,   rabbit.published_messages[0][:content_encoding])
        assert_equal(Time.now.to_i,    rabbit.published_messages[0][:timestamp])
        assert_equal("",               rabbit.published_messages[0][:body])
        assert_equal("GET",            rabbit.published_messages[0][:headers][RackRabbit::HEADER::METHOD])
        assert_equal("/path",          rabbit.published_messages[0][:headers][RackRabbit::HEADER::PATH])
        assert_equal("request_header", rabbit.published_messages[0][:headers]["additional"])

      end # Timecop.freeze

    end

    #--------------------------------------------------------------------------

    def test_POST

      Timecop.freeze do

        client = build_client
        reply  = build_message(:correlation_id => CORRELATION_ID, :status => 200, :body => "POST OK", :headers => { "additional" => "reply_header" })
        rabbit = client.rabbit

        prime_reply(client, reply)   # prime rabbit with a pending reply message

        response = client.post(QUEUE, "/path", BODY, {
          :id               => CORRELATION_ID,    # dependency inject generated message ID
          :priority         => PRIORITY,
          :content_type     => CONTENT::JSON,
          :content_encoding => CONTENT::ASCII,
          :headers          => { "additional" => "request_header" }
        })

        assert_equal(200,            response.status)
        assert_equal("POST OK",      response.body)
        assert_equal("reply_header", response.headers["additional"])

        assert_equal([reply],          rabbit.subscribed_messages)
        assert_equal(1,                rabbit.published_messages.length)
        assert_equal(CORRELATION_ID,   rabbit.published_messages[0][:correlation_id])
        assert_equal(QUEUE,            rabbit.published_messages[0][:routing_key])
        assert_equal(REPLY_QUEUE,      rabbit.published_messages[0][:reply_to])
        assert_equal(PRIORITY,         rabbit.published_messages[0][:priority])
        assert_equal(CONTENT::JSON,    rabbit.published_messages[0][:content_type])
        assert_equal(CONTENT::ASCII,   rabbit.published_messages[0][:content_encoding])
        assert_equal(Time.now.to_i,    rabbit.published_messages[0][:timestamp])
        assert_equal(BODY,             rabbit.published_messages[0][:body])
        assert_equal("POST",           rabbit.published_messages[0][:headers][RackRabbit::HEADER::METHOD])
        assert_equal("/path",          rabbit.published_messages[0][:headers][RackRabbit::HEADER::PATH])
        assert_equal("request_header", rabbit.published_messages[0][:headers]["additional"])

      end # Timecop.freeze

    end

    #--------------------------------------------------------------------------

    def test_PUT

      Timecop.freeze do

        client = build_client
        reply  = build_message(:correlation_id => CORRELATION_ID, :status => 200, :body => "PUT OK", :headers => { "additional" => "reply_header" })
        rabbit = client.rabbit

        prime_reply(client, reply)   # prime rabbit with a pending reply message

        response = client.put(QUEUE, "/path", BODY, {
          :id               => CORRELATION_ID,    # dependency inject generated message ID
          :priority         => PRIORITY,
          :content_type     => CONTENT::JSON,
          :content_encoding => CONTENT::ASCII,
          :headers          => { "additional" => "request_header" }
        })

        assert_equal(200,            response.status)
        assert_equal("PUT OK",       response.body)
        assert_equal("reply_header", response.headers["additional"])

        assert_equal([reply],          rabbit.subscribed_messages)
        assert_equal(1,                rabbit.published_messages.length)
        assert_equal(CORRELATION_ID,   rabbit.published_messages[0][:correlation_id])
        assert_equal(QUEUE,            rabbit.published_messages[0][:routing_key])
        assert_equal(REPLY_QUEUE,      rabbit.published_messages[0][:reply_to])
        assert_equal(PRIORITY,         rabbit.published_messages[0][:priority])
        assert_equal(CONTENT::JSON,    rabbit.published_messages[0][:content_type])
        assert_equal(CONTENT::ASCII,   rabbit.published_messages[0][:content_encoding])
        assert_equal(Time.now.to_i,    rabbit.published_messages[0][:timestamp])
        assert_equal(BODY,             rabbit.published_messages[0][:body])
        assert_equal("PUT",            rabbit.published_messages[0][:headers][RackRabbit::HEADER::METHOD])
        assert_equal("/path",          rabbit.published_messages[0][:headers][RackRabbit::HEADER::PATH])
        assert_equal("request_header", rabbit.published_messages[0][:headers]["additional"])

      end # Timecop.freeze

    end

    #--------------------------------------------------------------------------

    def test_DELETE

      Timecop.freeze do

        client = build_client
        reply  = build_message(:correlation_id => CORRELATION_ID, :status => 200, :body => "DELETE OK", :headers => { "additional" => "reply_header" })
        rabbit = client.rabbit

        prime_reply(client, reply)   # prime rabbit with a pending reply message

        response = client.delete(QUEUE, "/path", {
          :id               => CORRELATION_ID,    # dependency inject generated message ID
          :priority         => PRIORITY,
          :content_type     => CONTENT::JSON,
          :content_encoding => CONTENT::ASCII,
          :headers          => { "additional" => "request_header" }
        })

        assert_equal(200,            response.status)
        assert_equal("DELETE OK",    response.body)
        assert_equal("reply_header", response.headers["additional"])

        assert_equal([reply],          rabbit.subscribed_messages)
        assert_equal(1,                rabbit.published_messages.length)
        assert_equal(CORRELATION_ID,   rabbit.published_messages[0][:correlation_id])
        assert_equal(QUEUE,            rabbit.published_messages[0][:routing_key])
        assert_equal(REPLY_QUEUE,      rabbit.published_messages[0][:reply_to])
        assert_equal(PRIORITY,         rabbit.published_messages[0][:priority])
        assert_equal(CONTENT::JSON,    rabbit.published_messages[0][:content_type])
        assert_equal(CONTENT::ASCII,   rabbit.published_messages[0][:content_encoding])
        assert_equal(Time.now.to_i,    rabbit.published_messages[0][:timestamp])
        assert_equal("",               rabbit.published_messages[0][:body])
        assert_equal("DELETE",         rabbit.published_messages[0][:headers][RackRabbit::HEADER::METHOD])
        assert_equal("/path",          rabbit.published_messages[0][:headers][RackRabbit::HEADER::PATH])
        assert_equal("request_header", rabbit.published_messages[0][:headers]["additional"])

      end # Timecop.freeze

    end

    #==========================================================================
    # PRIVATE IMPLEMTATION HELPERS
    #==========================================================================

    private

    def prime_reply(client, *messages)
      messages.each do |m|
        client.rabbit.prime(m)
      end 
    end

  end # class TestClient
end # module RackRabbit
