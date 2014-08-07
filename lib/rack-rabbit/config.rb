require 'logger'

module RackRabbit

  class Config

    #--------------------------------------------------------------------------

    def initialize(options)

      @options = options || {}

      @options[:logger] ||= build_default_logger

      raise ArgumentError, "missing rackup file #{rackup}" unless File.readable?(rackup)

    end

    #--------------------------------------------------------------------------

    def rackup
      @options[:rackup] || defaults[:rackup]
    end

    def logger
      @options[:logger] || defaults[:logger]
    end

    def log_level
      @options[:log_level] || defaults[:log_level]
    end

    def workers
      @options[:workers] || defaults[:workers]
    end

    def min_workers
      @options[:min_workers] || defaults[:min_workers]
    end

    def max_workers
      @options[:max_workers] || defaults[:max_workers]
    end

    def queue
      @options[:queue] || defaults[:queue]
    end

    def app_id
      @options[:app_id] || defaults[:app_id]
    end

    #--------------------------------------------------------------------------

    def defaults
      @defaults ||= {
        :rackup      => 'config.ru',
        :log_level   => :info,
        :workers     => 2,
        :min_workers => 1,
        :max_workers => 100,
        :queue       => 'rack-rabbit',
        :app_id      => 'rack-rabbit'
      }
    end

    #--------------------------------------------------------------------------

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

    #--------------------------------------------------------------------------

  end

end
