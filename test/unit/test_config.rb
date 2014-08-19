require_relative '../test_case'

require 'rack-rabbit/config'

module RackRabbit
  class TestConfig < TestCase

    #--------------------------------------------------------------------------

    def test_construct_with_defaults

      config = RackRabbit::Config.new(:rack_file => SIMPLE_RACK_APP)

      assert_equal("127.0.0.1",         config.rabbit[:host])
      assert_equal("5672",              config.rabbit[:port])
      assert_equal("bunny",             config.rabbit[:adapter])
      assert_equal(nil,                 config.config_file)
      assert_equal(SIMPLE_RACK_APP,     config.rack_file)
      assert_equal("queue",             config.queue)
      assert_equal("rack-rabbit-queue", config.app_id)
      assert_equal(2,                   config.workers)
      assert_equal(1,                   config.min_workers)
      assert_equal(32,                  config.max_workers)
      assert_equal(nil,                 config.acknowledge)
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

      config = RackRabbit::Config.new(:rack_file => SIMPLE_RACK_APP,
        :rabbit      => { :host => "10.10.10.10", :port => "1234", :adapter => "amqp" },
        :queue       => "myqueue",
        :app_id      => "myapp",
        :workers     => 7,
        :min_workers => 3,
        :max_workers => 42,
        :acknowledge => true,
        :preload_app => true,
        :log_level   => :fatal,
        :logger      => logger,
        :daemonize   => true,
        :logfile     => "myapp.log",
        :pidfile     => "myapp.pid"
      )
        
      assert_equal("10.10.10.10",                 config.rabbit[:host])
      assert_equal("1234",                        config.rabbit[:port])
      assert_equal("amqp",                        config.rabbit[:adapter])
      assert_equal(nil,                           config.config_file)
      assert_equal(SIMPLE_RACK_APP,               config.rack_file)
      assert_equal("myqueue",                     config.queue)
      assert_equal("myapp",                       config.app_id)
      assert_equal(7,                             config.workers)
      assert_equal(3,                             config.min_workers)
      assert_equal(42,                            config.max_workers)
      assert_equal(true,                          config.acknowledge)
      assert_equal(true,                          config.preload_app)
      assert_equal(:fatal,                        config.log_level)
      assert_equal(logger,                        config.logger)
      assert_equal(true,                          config.daemonize)
      assert_equal(File.expand_path("myapp.log"), config.logfile)
      assert_equal(File.expand_path("myapp.pid"), config.pidfile)

    end

    #--------------------------------------------------------------------------

    def test_construct_from_configuration_file

      config = RackRabbit::Config.new(:config_file => SAMPLE_CONFIG)

      assert_equal("10.10.10.10",                 config.rabbit[:host])
      assert_equal("1234",                        config.rabbit[:port])
      assert_equal("amqp",                        config.rabbit[:adapter])
      assert_equal(SAMPLE_CONFIG,                 config.config_file)
      assert_equal(SIMPLE_RACK_APP,               config.rack_file)
      assert_equal("myqueue",                     config.queue)
      assert_equal("myapp",                       config.app_id)
      assert_equal(7,                             config.workers)
      assert_equal(3,                             config.min_workers)
      assert_equal(42,                            config.max_workers)
      assert_equal(true,                          config.acknowledge)
      assert_equal(true,                          config.preload_app)
      assert_equal(:fatal,                        config.log_level)
      assert_equal("MyLogger",                    config.logger.class.name)
      assert_equal(true,                          config.daemonize)
      assert_equal(File.expand_path("myapp.log"), config.logfile)
      assert_equal(File.expand_path("myapp.pid"), config.pidfile)

    end

    #--------------------------------------------------------------------------

  end
end
