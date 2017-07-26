require_relative '../test_case'

module RackRabbit
  class TestConfig < TestCase

    #--------------------------------------------------------------------------

    def test_construct_with_defaults

      config = default_config

      assert_equal("127.0.0.1",         config.rabbit[:host])
      assert_equal("5672",              config.rabbit[:port])
      assert_equal("bunny",             config.rabbit[:adapter])
      assert_equal(nil,                 config.config_file)
      assert_equal(DEFAULT_RACK_APP,    config.rack_file)
      assert_equal(nil,                 config.queue)
      assert_equal(nil,                 config.exchange)
      assert_equal(:direct,             config.exchange_type)
      assert_equal(nil,                 config.routing_key)
      assert_equal("rr-default-null",   config.app_id)
      assert_equal(1,                   config.workers)
      assert_equal(1,                   config.min_workers)
      assert_equal(32,                  config.max_workers)
      assert_equal(nil,                 config.ack)
      assert_equal(nil,                 config.preload_app)
      assert_equal(:info,               config.log_level)
      assert_equal(Logger,              config.logger.class)
      assert_equal(nil,                 config.daemonize)
      assert_equal(nil,                 config.logfile)
      assert_equal(nil,                 config.pidfile)

    end

    #--------------------------------------------------------------------------

    def test_construct_with_options

      logger = Logger.new($stdout)

      config = build_config(
        :rack_file     => DEFAULT_RACK_APP,
        :rabbit        => { :host => "10.10.10.10", :port => "1234", :adapter => "amqp" },
        :queue         => "myqueue",
        :exchange      => "myexchange",
        :exchange_type => "fanout",
        :routing_key   => "myroute",
        :app_id        => "myapp",
        :workers       => 7,
        :min_workers   => 3,
        :max_workers   => 42,
        :ack           => true,
        :preload_app   => true,
        :log_level     => :fatal,
        :logger        => logger,
        :daemonize     => true,
        :logfile       => "myapp.log",
        :pidfile       => "myapp.pid"
      )
      
      assert_equal("10.10.10.10",                 config.rabbit[:host])
      assert_equal("1234",                        config.rabbit[:port])
      assert_equal("amqp",                        config.rabbit[:adapter])
      assert_equal(nil,                           config.config_file)
      assert_equal(DEFAULT_RACK_APP,              config.rack_file)
      assert_equal("myqueue",                     config.queue)
      assert_equal("myexchange",                  config.exchange)
      assert_equal(:fanout,                       config.exchange_type)
      assert_equal("myroute",                     config.routing_key)
      assert_equal("myapp",                       config.app_id)
      assert_equal(7,                             config.workers)
      assert_equal(3,                             config.min_workers)
      assert_equal(42,                            config.max_workers)
      assert_equal(true,                          config.ack)
      assert_equal(true,                          config.preload_app)
      assert_equal(:fatal,                        config.log_level)
      assert_equal(logger,                        config.logger)
      assert_equal(true,                          config.daemonize)
      assert_equal(File.expand_path("myapp.log"), config.logfile)
      assert_equal(File.expand_path("myapp.pid"), config.pidfile)

    end

    #--------------------------------------------------------------------------

    def test_construct_from_configuration_file

      config = build_config(:config_file => CUSTOM_CONFIG)

      assert_equal("10.10.10.10",                 config.rabbit[:host])
      assert_equal("1234",                        config.rabbit[:port])
      assert_equal("amqp",                        config.rabbit[:adapter])
      assert_equal(CUSTOM_CONFIG,                 config.config_file)
      assert_equal(CUSTOM_RACK_APP,               config.rack_file)
      assert_equal("myqueue",                     config.queue)
      assert_equal("myexchange",                  config.exchange)
      assert_equal(:topic,                        config.exchange_type)
      assert_equal("myroute",                     config.routing_key)
      assert_equal("myapp",                       config.app_id)
      assert_equal(7,                             config.workers)
      assert_equal(3,                             config.min_workers)
      assert_equal(42,                            config.max_workers)
      assert_equal(true,                          config.ack)
      assert_equal(true,                          config.preload_app)
      assert_equal(:fatal,                        config.log_level)
      assert_equal("MyLogger",                    config.logger.class.name)
      assert_equal(true,                          config.daemonize)
      assert_equal(File.expand_path("myapp.log"), config.logfile)
      assert_equal(File.expand_path("myapp.pid"), config.pidfile)

    end

    #--------------------------------------------------------------------------

    def test_rabbit

      config = default_config

      assert_equal("127.0.0.1", config.rabbit[:host])
      assert_equal("5672",      config.rabbit[:port])
      assert_equal("bunny",     config.rabbit[:adapter])

      config.rabbit :host    => "10.10.10.10"
      config.rabbit :port    => "1234"
      config.rabbit :adapter => "amqp"

      assert_equal("10.10.10.10", config.rabbit[:host])
      assert_equal("1234",        config.rabbit[:port])
      assert_equal("amqp",        config.rabbit[:adapter])

      config.rabbit :host => "1.2.3.4", :port => "5678", :adapter => "hare"

      assert_equal("1.2.3.4", config.rabbit[:host])
      assert_equal("5678",    config.rabbit[:port])
      assert_equal("hare",    config.rabbit[:adapter])

    end

    #--------------------------------------------------------------------------

    def test_config_file
      config = build_config
      assert_equal(nil, config.config_file)
      config.config_file "examples/custom.conf"
      assert_equal(File.expand_path("examples/custom.conf"), config.config_file)
    end

    #--------------------------------------------------------------------------

    def test_rack_file
      config = build_config
      assert_equal(DEFAULT_RACK_APP, config.rack_file)
      config.rack_file CUSTOM_RACK_APP
      assert_equal(CUSTOM_RACK_APP, config.rack_file)
    end

    def test_rack_file_is_required
      assert_raises_argument_error("missing rack config file") do
        RackRabbit::Config.new(:queue => "myqueue")
      end
      assert_raises_argument_error("missing rack config file") do
        RackRabbit::Config.new(:queue => "myqueue", :rack_file => "/no/such/path/config.ru")
      end
    end

    def test_rack_file_default_is_relative_to_config_file
      config = build_config(:config_file => EMPTY_CONFIG)
      assert_equal(File.join(File.dirname(EMPTY_CONFIG), "config.ru"), config.rack_file)
    end

    #--------------------------------------------------------------------------

    def test_queue
      config = build_config
      assert_equal(nil, config.queue)
      config.queue "myqueue"
      assert_equal("myqueue", config.queue)
    end

    def test_exchange
      config = build_config
      assert_equal(nil, config.exchange)
      config.exchange "myexchange"
      assert_equal("myexchange", config.exchange)
    end

    def test_exchange_type
      config = build_config
      assert_equal(:direct, config.exchange_type)
      config.exchange_type :fanout
      assert_equal(:fanout, config.exchange_type)
    end

    def test_routing_key
      config = build_config
      assert_equal(nil, config.routing_key)
      config.routing_key "myroute"
      assert_equal("myroute", config.routing_key)
    end

    def test_queue_or_exchange_is_required
      assert_raises_argument_error("must provide EITHER a :queue OR an :exchange") do
        _bad = build_config(:validate => true)
      end
      _good1 = build_config(:validate => true, :queue    => "myqueue")
      _good2 = build_config(:validate => true, :exchange => "myexchange")
    end

    #--------------------------------------------------------------------------

    def test_app_id
      config = build_config
      assert_equal("rr-default-null", config.app_id)
      config.app_id "myapp"
      assert_equal("myapp", config.app_id)
    end

    def test_app_id_defaults_include_exchange_and_queue_or_route

      config = build_config(:exchange => "myexchange", :queue => "myqueue", :routing_key => "myroute")
      assert_equal("rr-myexchange-myqueue", config.app_id) 

      config = build_config(:exchange => "myexchange", :queue => "myqueue", :routing_key => nil)
      assert_equal("rr-myexchange-myqueue", config.app_id) 

      config = build_config(:exchange => "myexchange", :queue => nil,       :routing_key => "myroute")
      assert_equal("rr-myexchange-myroute", config.app_id) 

      config = build_config(:exchange => "myexchange", :queue => nil,       :routing_key => nil)
      assert_equal("rr-myexchange-null", config.app_id) 

    end

    #--------------------------------------------------------------------------

    def test_workers
      config = build_config
      assert_equal(1, config.workers)
      config.workers 7
      assert_equal(7, config.workers)
    end

    def test_min_workers
      config = build_config
      assert_equal(1, config.min_workers)
      config.min_workers 8
      assert_equal(8, config.min_workers)
    end

    def test_max_workers
      config = build_config
      assert_equal(32, config.max_workers)
      config.max_workers 64
      assert_equal(64, config.max_workers)
    end

    #--------------------------------------------------------------------------

    def test_ack
      config = build_config
      assert_equal(nil, config.ack)
      config.ack true
      assert_equal(true, config.ack)
      config.ack false
      assert_equal(false, config.ack)
    end

    #--------------------------------------------------------------------------

    def test_preload_app
      config = build_config
      assert_equal(nil, config.preload_app)
      config.preload_app true
      assert_equal(true, config.preload_app)
      config.preload_app false
      assert_equal(false, config.preload_app)
    end

    #--------------------------------------------------------------------------

    def test_daemonize
      config = build_config
      assert_equal(nil, config.daemonize)
      config.daemonize true
      assert_equal(true, config.daemonize)
      config.daemonize false
      assert_equal(false, config.daemonize)
    end

    #--------------------------------------------------------------------------

    def test_log_level
      config = build_config
      assert_equal(:info, config.log_level)
      config.log_level :debug
      assert_equal(:debug, config.log_level)
    end

    #--------------------------------------------------------------------------

    def test_logger

      config = default_config

      assert_equal(Logger,       config.logger.class)
      assert_equal(true,         config.logger.respond_to?(:master_pid))
      assert_equal($$,           config.logger.master_pid)
      assert_equal(Proc,         config.logger.formatter.class)
      assert_equal(Logger::INFO, config.logger.level)

      config.logger CustomLogger.new($stderr, Logger::WARN)

      assert_equal(CustomLogger, config.logger.class)
      assert_equal(false,        config.logger.respond_to?(:master_pid))
      assert_equal(NilClass,     config.logger.formatter.class)
      assert_equal(Logger::WARN, config.logger.level)

    end

    #--------------------------------------------------------------------------

    def test_logfile
      config = build_config
      assert_equal(nil, config.logfile)
      config.logfile "myapp.log"
      assert_equal(File.expand_path("myapp.log"), config.logfile)
    end

    def test_logfile_defaults_when_daemonized
      config = build_config(:daemonize => true, :app_id => "myapp", :skip_filesystem_checks => true)
      assert_equal("/var/log/myapp.log", config.logfile)
    end

    #--------------------------------------------------------------------------

    def test_pidfile
      config = build_config
      assert_equal(nil, config.pidfile)
      config.pidfile "myapp.pid"
      assert_equal(File.expand_path("myapp.pid"), config.pidfile)
    end

    def test_pidfile_defaults_when_daemonized
      config = build_config(:daemonize => true, :app_id => "myapp", :skip_filesystem_checks => true)
      assert_equal("/var/run/myapp.pid", config.pidfile)
    end

    #--------------------------------------------------------------------------

    def test_before_fork
      config = build_config
      server = nil
      config.before_fork do |s|
        server = s
      end
      config.before_fork(:server)
      assert_equal(:server, server, "verify block got called")
    end

    def test_after_fork
      config = build_config
      server = nil
      worker = nil
      config.after_fork do |s, w|
        server = s
        worker = w
      end
      config.after_fork(:server, :worker)
      assert_equal(:server, server, "verify block got called")
      assert_equal(:worker, worker, "verify block got called")
    end

    #--------------------------------------------------------------------------

    def test_rack_env
      config = build_config(:app_id => APP_ID)
      assert_equal(Rack::VERSION, config.rack_env['rack.version'])
      assert_equal(config.logger, config.rack_env['rack.logger'])
      assert_equal($stderr,       config.rack_env['rack.errors'])
      assert_equal(false,         config.rack_env['rack.multithread'])
      assert_equal(true,          config.rack_env['rack.multiprocess'])
      assert_equal(false,         config.rack_env['rack.run_once'])
      assert_equal('http',        config.rack_env['rack.url_scheme'])
      assert_equal(APP_ID,        config.rack_env['SERVER_NAME'])
    end

    #==========================================================================
    # private helper methods
    #==========================================================================

    private

    class CustomLogger < Logger
      def initialize(file, level)
        super(file)
        self.level = level
      end
    end

    #--------------------------------------------------------------------------

  end
end
