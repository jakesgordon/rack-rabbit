require_relative '../test_case'

require 'rack-rabbit/worker'

module RackRabbit
  class TestWorker < TestCase

    #--------------------------------------------------------------------------

    def test_handle_message

      config   = build_config(:rack_file => DEFAULT_RACK_APP)
      app      = build_app(config.rack_file)
      worker   = Worker.new(config, app)
      message  = build_message
      response = worker.handle(message)

      assert_equal(200,           response.status)
      assert_equal("Hello World", response.body)
      assert_equal({},            response.headers)

    end

    #--------------------------------------------------------------------------

    def test_handle_message_that_causes_rack_app_to_raise_an_exception

      config   = build_config(:rack_file => ERROR_RACK_APP)
      app      = build_app(config.rack_file)
      worker   = Worker.new(config, app)
      message  = build_message
      response = worker.handle(message)

      assert_equal(500,                     response.status)
      assert_equal("Internal Server Error", response.body)
      assert_equal({},                      response.headers)

    end

    #--------------------------------------------------------------------------

    def test_handle_message_that_expects_a_reply

      # TODO: think I need more advanced mocking (mocha?) to make this work

    end

    #--------------------------------------------------------------------------

    def test_succesful_message_is_acked

      config   = build_config(:rack_file => DEFAULT_RACK_APP, :acknowledge => true)
      app      = build_app(config.rack_file)
      worker   = Worker.new(config, app)
      message  = build_message(:delivery_tag => DELIVERY_TAG)
      response = worker.handle(message)

      assert_equal(200,            response.status)
      assert_equal("Hello World",  response.body)
      assert_equal([DELIVERY_TAG], worker.rabbit.acked_messages)
      assert_equal([],             worker.rabbit.rejected_messages)
      assert_equal([],             worker.rabbit.requeued_messages)

    end

    #--------------------------------------------------------------------------

    def test_failed_message_is_rejected

      config   = build_config(:rack_file => ERROR_RACK_APP, :acknowledge => true)
      app      = build_app(config.rack_file)
      worker   = Worker.new(config, app)
      message  = build_message(:delivery_tag => DELIVERY_TAG)
      response = worker.handle(message)

      assert_equal(500,                     response.status)
      assert_equal("Internal Server Error", response.body)
      assert_equal([],                      worker.rabbit.acked_messages)
      assert_equal([DELIVERY_TAG],          worker.rabbit.rejected_messages)
      assert_equal([],                      worker.rabbit.requeued_messages)

    end

    #--------------------------------------------------------------------------

    def test_rack_environment_is_generated_correctly_from_incoming_message

      config = build_config(:rack_file => DEFAULT_RACK_APP, :app_id => APP_ID)
      app    = build_app(config.rack_file)

      message = build_message({
        :content_type     => CONTENT_TYPE,
        :content_encoding => CONTENT_ENCODING,
        :headers          => {
          RackRabbit::HEADER::METHOD => :GET,
          RackRabbit::HEADER::PATH   => URI,
        },
        :body => BODY
      })

      worker = Worker.new(config, app)
      env    = worker.build_env(message)

      assert_equal(message,       env['rabbit.message'])
      assert_equal(BODY,          env['rack.input'].read)
      assert_equal(:GET,          env['REQUEST_METHOD'])
      assert_equal(URI,           env['REQUEST_PATH'])
      assert_equal(PATH,          env['PATH_INFO'])
      assert_equal(QUERY,         env['QUERY_STRING'])
      assert_equal(CONTENT_TYPE,  env['CONTENT_TYPE'])
      assert_equal(BODY.length,   env['CONTENT_LENGTH'])
      assert_equal(Rack::VERSION, env['rack.version'])
      assert_equal(config.logger, env['rack.logger'])
      assert_equal($stderr,       env['rack.errors'])
      assert_equal(false,         env['rack.multithread'])
      assert_equal(true,          env['rack.multiprocess'])
      assert_equal(false,         env['rack.run_once'])
      assert_equal('http',        env['rack.url_scheme'])
      assert_equal(APP_ID,        env['SERVER_NAME'])

    end

    #--------------------------------------------------------------------------

    def test_rabbit_response_is_generated_correctly

      config = build_config(:rack_file => DEFAULT_RACK_APP, :app_id => APP_ID)
      app    = build_app(config.rack_file)

      message = build_message({
        :reply_to         => REPLY_TO,
        :correlation_id   => CORRELATION_ID,
        :content_type     => "request.content.type",
        :content_encoding => "request.content.encoding",
        :headers => {
          RackRabbit::HEADER::METHOD => "request.method",
          RackRabbit::HEADER::PATH   => "request.path",
        },
        :body => "request.body"
      })

      response = build_response(200, {
        RackRabbit::HEADER::CONTENT_TYPE     => "response.content.type",
        RackRabbit::HEADER::CONTENT_ENCODING => "response.content.encoding",
        :additional => :header
      }, "response.body")

      Timecop.freeze do

        worker     = Worker.new(config, app)
        properties = worker.response_properties(message, response)

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

  end # class TestWorker
end # module RackRabbit

