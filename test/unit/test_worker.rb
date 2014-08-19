require_relative '../test_case'

require 'rack-rabbit/worker'

module RackRabbit
  class TestWorker < TestCase

    #--------------------------------------------------------------------------

    include MocksRabbit

    #--------------------------------------------------------------------------

    attr_reader :server, :app

    def setup
      @server = build_server(:rack_file => DEFAULT_RACK_APP, :app_id => APP_ID, :preload_app => true)
      @app    = server.app
    end

    #--------------------------------------------------------------------------

    def test_generated_rack_environment

      message = build_message({
        :content_type     => CONTENT_TYPE,
        :content_encoding => CONTENT_ENCODING,
        :headers          => {
          RackRabbit::HEADER::METHOD => :GET,
          RackRabbit::HEADER::PATH   => URI,
        },
        :body => BODY
      })

      worker  = Worker.new(server, app)
      env     = worker.build_env(message)

      assert_equal(message,       env['rabbit.message'])
      assert_equal(BODY,          env['rack.input'].read)
      assert_equal(:GET,          env['REQUEST_METHOD'])
      assert_equal(URI,           env['REQUEST_PATH'])
      assert_equal(PATH,          env['PATH_INFO'])
      assert_equal(QUERY,         env['QUERY_STRING'])
      assert_equal(CONTENT_TYPE,  env['CONTENT_TYPE'])
      assert_equal(BODY.length,   env['CONTENT_LENGTH'])
      assert_equal(Rack::VERSION, env['rack.version'])
      assert_equal(server.logger, env['rack.logger'])
      assert_equal($stderr,       env['rack.errors'])
      assert_equal(false,         env['rack.multithread'])
      assert_equal(true,          env['rack.multiprocess'])
      assert_equal(false,         env['rack.run_once'])
      assert_equal('http',        env['rack.url_scheme'])
      assert_equal(APP_ID,        env['SERVER_NAME'])

    end

    #--------------------------------------------------------------------------

    def test_handle_message
    end

    #--------------------------------------------------------------------------

    def test_rabbit_response_properties
    end

    #--------------------------------------------------------------------------

  end # class TestWorker
end # module RackRabbit

