require_relative '../test_case'

module RackRabbit
  class TestMessage < TestCase

    #--------------------------------------------------------------------------

    def test_default_message

      message = build_message

      assert_equal(nil,   message.delivery_tag)
      assert_equal(nil,   message.reply_to)
      assert_equal(nil,   message.correlation_id)
      assert_equal(nil,   message.body)
      assert_equal({},    message.headers)
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

      headers = { "additional" => "header" }

      message = build_message({
        :delivery_tag     => DELIVERY_TAG,
        :reply_to         => REPLY_TO,
        :correlation_id   => CORRELATION_ID,
        :content_type     => CONTENT::PLAIN_TEXT,
        :content_encoding => CONTENT::UTF8,
        :method           => :POST,
        :path             => URI,
        :status           => 200,
        :headers          => headers,
        :body             => BODY
      })

      assert_equal(DELIVERY_TAG,        message.delivery_tag)
      assert_equal(REPLY_TO,            message.reply_to)
      assert_equal(CORRELATION_ID,      message.correlation_id)
      assert_equal(BODY,                message.body)
      assert_equal(headers,             message.headers)
      assert_equal(:POST,               message.method)
      assert_equal(URI,                 message.uri)
      assert_equal(200,                 message.status)
      assert_equal(PATH,                message.path)
      assert_equal(QUERY,               message.query)
      assert_equal(CONTENT::PLAIN_TEXT, message.content_type)
      assert_equal(CONTENT::UTF8,       message.content_encoding)
      assert_equal(BODY.length,         message.content_length)
      assert_equal(true,                message.should_reply?)
      assert_equal(false,               message.acknowledged?)
      assert_equal(false,               message.rejected?)
      assert_equal(false,               message.confirmed?)

    end

    #--------------------------------------------------------------------------

    def test_get_rack_env

      config = build_config(:app_id => APP_ID)

      message = build_message({
        :method           => :GET,
        :path             => URI,
        :body             => BODY,
        :content_type     => CONTENT::PLAIN_TEXT,
        :content_encoding => CONTENT::UTF8,
        :headers          => { "additional" => "header" }
      })

      env = message.get_rack_env(config.rack_env)

      assert_equal(message,                  env['rabbit.message'])
      assert_equal(BODY,                     env['rack.input'].read)
      assert_equal(:GET,                     env['REQUEST_METHOD'])
      assert_equal(URI,                      env['REQUEST_PATH'])
      assert_equal(PATH,                     env['PATH_INFO'])
      assert_equal(QUERY,                    env['QUERY_STRING'])
      assert_equal(CONTENT::PLAIN_TEXT_UTF8, env['CONTENT_TYPE'])
      assert_equal(BODY.length,              env['CONTENT_LENGTH'])
      assert_equal(Rack::VERSION,            env['rack.version'])
      assert_equal(config.logger,            env['rack.logger'])
      assert_equal($stderr,                  env['rack.errors'])
      assert_equal(false,                    env['rack.multithread'])
      assert_equal(true,                     env['rack.multiprocess'])
      assert_equal(false,                    env['rack.run_once'])
      assert_equal('http',                   env['rack.url_scheme'])
      assert_equal(APP_ID,                   env['SERVER_NAME'])
      assert_equal("header",                 env["additional"])

    end

    #--------------------------------------------------------------------------

    def test_get_rack_env_content_type_and_encoding_sensible_defaults

      m1 = build_message({ :content_type => nil,    :content_encoding => nil })
      m2 = build_message({ :content_type => "TYPE", :content_encoding => nil })
      m3 = build_message({ :content_type => nil,    :content_encoding => "ENCODING" })
      m4 = build_message({ :content_type => "TYPE", :content_encoding => "ENCODING" })

      assert_equal("text/plain; charset=\"utf-8\"",     m1.get_rack_env['CONTENT_TYPE'])
      assert_equal(      "TYPE; charset=\"utf-8\"",     m2.get_rack_env['CONTENT_TYPE'])
      assert_equal("text/plain; charset=\"ENCODING\"",  m3.get_rack_env['CONTENT_TYPE'])
      assert_equal(      "TYPE; charset=\"ENCODING\"",  m4.get_rack_env['CONTENT_TYPE'])

    end

    #--------------------------------------------------------------------------

    def test_should_reply?
      m1 = build_message(:reply_to => nil)
      m2 = build_message(:reply_to => REPLY_TO)
      assert_equal(false, m1.should_reply?)
      assert_equal(true,  m2.should_reply?)
    end

    #--------------------------------------------------------------------------

    def test_get_reply_properties

      config = build_config(:app_id => APP_ID)

      message = build_message({
        :reply_to         => REPLY_TO,
        :correlation_id   => CORRELATION_ID,
        :content_type     => "request.content.type",
        :content_encoding => "request.content.encoding",
        :method           => "request.method",
        :path             => "request.path",
        :body             => "request.body"
      })

      response = build_response(200, "response.body", {
        :content_type     => "response.content.type",
        :content_encoding => "response.content.encoding",
        "additional"      => "header"
      })

      Timecop.freeze do

        properties = message.get_reply_properties(response, config)

        assert_equal(APP_ID,                      properties[:app_id])
        assert_equal(REPLY_TO,                    properties[:routing_key])
        assert_equal(CORRELATION_ID,              properties[:correlation_id])
        assert_equal(Time.now.to_i,               properties[:timestamp])
        assert_equal("response.content.type",     properties[:content_type])
        assert_equal("response.content.encoding", properties[:content_encoding])
        assert_equal("header",                    properties[:headers]["additional"])

      end

    end

    #--------------------------------------------------------------------------

    def test_confirm_successful

      message = build_message(:delivery_tag => DELIVERY_TAG)
      assert_equal(false, message.acknowledged?)
      assert_equal(false, message.rejected?)
      assert_equal(false, message.confirmed?)

      message.confirm(true)
      assert_equal(true,  message.acknowledged?)
      assert_equal(false, message.rejected?)
      assert_equal(true,  message.confirmed?)

    end

    #--------------------------------------------------------------------------

    def test_confirm_failure

      message = build_message(:delivery_tag => DELIVERY_TAG)
      assert_equal(false, message.acknowledged?)
      assert_equal(false, message.rejected?)
      assert_equal(false, message.confirmed?)

      message.confirm(false)

      assert_equal(false, message.acknowledged?)
      assert_equal(true,  message.rejected?)
      assert_equal(true,  message.confirmed?)

    end

    #--------------------------------------------------------------------------

  end # class TestMessage
end # module RackRabbit

