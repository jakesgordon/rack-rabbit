require 'logger'

module RackRabbit

  class Config

    def initialize(rackup, options)
      @options = options
      raise ArgumentError, "missing rackup file #{rackup}" unless File.readable?(rackup)
      options[:rackup] = rackup
      options[:logger] ||= build_default_logger
    end

    def self.declare_option(name)
      define_method(name) do
        @options[name] || defaults[name]
      end
    end

    declare_option :logger
    declare_option :log_level
    declare_option :rackup
    declare_option :workers
    declare_option :min_workers
    declare_option :max_workers
    declare_option :queue
    declare_option :app_id

    def defaults
      @defaults ||= {
        :log_level   => :info,
        :rackup      => 'config.ru',
        :workers     => 2,
        :min_workers => 1,
        :max_workers => 100,
        :queue       => 'rack-rabbit',
        :app_id      => 'rack-rabbit'
      }
    end

    def build_default_logger
      master_pid = $$
      logger = Logger.new($stdout)
      logger.formatter = proc do |severity, datetime, progname, msg|
        "[#{Process.pid}:#{$$ == master_pid ? "SERVER" : "worker"}] #{datetime} #{msg}\n"
      end
      logger.level = case log_level.to_s.downcase.to_sym 
                     when :fatal then Logger::FATAL
                     when :error then Logger::ERROR
                     when :warn  then Logger::WARN
                     when :info  then Logger::INFO
                     when :debug then Logger::DEBUG
                     else
                       Logger::INFO
                     end
      logger
    end

  end

end
