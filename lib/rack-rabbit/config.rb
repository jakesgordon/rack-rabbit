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
      name     = name.to_sym
      default  = options[:default]
      sanitize = options[:sanitize]
      define_method name do |value = :not_provided|
        if value != :not_provided
          @options[name] = sanitize ? sanitize.call(value) : value
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

    def self.has_hook(name)
      name = name.to_sym
      define_method name do |*params, &block|
        if block
          @options[name] = block
        elsif @options[name].respond_to?(:call)
          @options[name].call(*params)
        end
      end
    end

    #--------------------------------------------------------------------------

    has_option :config_file
    has_option :rack_file,   :default => lambda{ File.join(File.dirname(config_file || ""), "config.ru") }
    has_option :queue,       :default => 'rack-rabbit'
    has_option :app_id,      :default => 'rack-rabbit'
    has_option :workers,     :default => 2
    has_option :min_workers, :default => 1
    has_option :max_workers, :default => 100
    has_option :preload_app, :default => false
    has_option :log_level,   :default => :info, :sanitize => lambda{|v| v.to_s.downcase.to_sym}
    has_option :logger,      :default => lambda{ build_default_logger }
    has_option :adapter,     :default => :bunny, :sanitize => lambda{|v| v.is_a?(Class) ? v : v.to_s.downcase.to_sym}

    has_hook :before_fork
    has_hook :after_fork

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
      raise ArgumentError, "invalid logger" unless [:fatal, :error, :warn, :info, :debug].all?{|method| logger.respond_to?(method)}
      validate_adapter
    end

    def validate_adapter
      if adapter.is_a?(Symbol)
        raise ArgumentError, "invalid adapter #{adapter}" unless [:bunny, :amqp].include?(adapter)
      elsif adapter.is_a?(Class)
        raise ArgumentError, "invalid custom adapter #{adapter}" unless [:connect, :disconnect, :subscribe, :publish].all?{|method| adapter.instance_methods.include?(method) }
      else
        raise ArgumentError, "missing adapter"
      end
    end

    def build_default_logger
      master_pid = $$
      logger = Logger.new($stderr)
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
