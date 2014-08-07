require 'logger'

module RackRabbit

  class Config

    #--------------------------------------------------------------------------

    def initialize(options)
      @options = options || {}
      reload
    end

    def reload
      instance_eval(File.read(config_file), config_file) if config_file && File.exists?(config_file)
      validate
    end

    #--------------------------------------------------------------------------

    def self.has_option(name, options = {})
      name    = name.to_sym 
      default = options[:default]
      define_method name do |value = :not_provided|
        if value != :not_provided
          @options[name] = value
        elsif @options[name].nil?
          if default.respond_to?(:call)
            @options[name] = instance_exec(&default)
          else
            @options[name] = default
          end
        end
        @options[name]
      end
    end

    #--------------------------------------------------------------------------

    has_option :config_file
    has_option :rack_file,   :default => 'config.ru'
    has_option :queue,       :default => 'rack-rabbit'
    has_option :app_id,      :default => 'rack-rabbit'
    has_option :workers,     :default => 2
    has_option :min_workers, :default => 1
    has_option :max_workers, :default => 100
    has_option :log_level,   :default => :info
    has_option :logger,      :default => lambda{ build_default_logger }

    #--------------------------------------------------------------------------

    def after_fork(server = nil, worker = nil, &block)
      if block_given?
        @options[:after_fork] = block
      elsif @options[:after_fork].respond_to?(:call)
        @options[:after_fork].call(server, worker)
      end
    end

    #--------------------------------------------------------------------------

    private

    def validate
      raise ArgumentError, "missing rack config file #{rack_file}" unless File.readable?(rack_file)
      raise ArgumentError, "invalid workers" unless workers.is_a?(Fixnum)
      raise ArgumentError, "invalid min_workers" unless min_workers.is_a?(Fixnum)
      raise ArgumentError, "invalid max_workers" unless max_workers.is_a?(Fixnum)
      raise ArgumentError, "invalid workers < min_workers" if workers < min_workers
      raise ArgumentError, "invalid workers > max_workers" if workers > max_workers
      raise ArgumentError, "invalid min_workers > max_workers" if min_workers > max_workers
      raise ArgumentError, "invalid logger" unless logger.respond_to?(:fatal) && logger.respond_to?(:error) && logger.respond_to?(:warn) && logger.respond_to?(:info) && logger.respond_to?(:debug)
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

    #--------------------------------------------------------------------------

  end

end
