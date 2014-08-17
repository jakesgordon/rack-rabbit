require 'logger'

module RackRabbit

  class Config

    #--------------------------------------------------------------------------

    def initialize(options)
      @values = {}
      options.each{|key, value| send(key, value)}
      reload
    end

    def reload
      instance_eval(File.read(config_file), config_file) if config_file && File.exists?(config_file)
      validate
    end

    #--------------------------------------------------------------------------

    def config_file(value = :missing)
      if value == :missing
        values[:config_file]
      else
        values[:config_file] = filename(value)
      end
    end

    def rack_file(value = :missing)
      if value == :missing
        values[:rack_file] ||= filename("config.ru", File.dirname(config_file || ""))
      else
        values[:rack_file] = filename(value, File.dirname(config_file || ""))
      end
    end

    def queue(value = :missing)
      if value == :missing
        values[:queue] ||= "queue"
      else
        values[:queue] = value
      end
    end

    def app_id(value = :missing)
      if value == :missing
        values[:app_id] ||= "rack-rabbit-#{queue}"
      else
        values[:app_id] = value
      end
    end

    def workers(value = :missing)
      if value == :missing
        values[:workers] ||= 2
      else
        values[:workers] = value.to_i
      end
    end

    def min_workers(value = :missing)
      if value == :missing
        values[:min_workers] ||= 1
      else
        values[:min_workers] = value.to_i
      end
    end

    def max_workers(value = :missing)
      if value == :missing
        values[:max_workers] ||= 32
      else
        values[:max_workers] = value.to_i
      end
    end

    def preload_app(value = :missing)
      if value == :missing
        values[:preload_app]
      else
        values[:preload_app] = !!value
      end
    end

    def log_level(value = :missing)
      if value == :missing
        values[:log_level] ||= :info
      else
        values[:log_level] = symbolize(value)
      end
    end

    def logger(value = :missing)
      if value == :missing
        values[:logger] ||= build_default_logger
      else
        values[:logger] = value
      end
    end

    def adapter(value = :missing)
      if value == :missing
        values[:adapter] ||= :bunny
      else
        values[:adapter] = value.is_a?(Class) ? value : symbolize(value)
      end
    end

    def daemonize(value = :missing)
      if value == :missing
        values[:daemonize]
      else
        values[:daemonize] = !!value
      end
    end

    def logfile(value = :missing)
      if value == :missing
        values[:logfile] ||= daemonize ? "/var/log/#{app_id}.log" : nil
      else
        values[:logfile] = filename(value)
      end
    end

    def pidfile(value = :missing)
      if value == :missing
        values[:pidfile] ||= daemonize ? "/var/run/#{app_id}.pid" : nil
      else
        values[:pidfile] = filename(value)
      end
    end

    def before_fork(server, &block)
      if block
        values[:before_fork] = block
      elsif values[:before_fork].respond_to?(:call)
        values[:before_fork].call(server)
      end
    end

    def after_fork(server, worker, &block)
      if block
        values[:after_fork] = block
      elsif values[:after_fork].respond_to?(:call)
        values[:after_fork].call(server, worker)
      end
    end

    #--------------------------------------------------------------------------

    private

    attr_reader :values

    def filename(path, relative_to = nil)
      File.expand_path(path, relative_to)
    end

    def symbolize(s)
      s.to_s.downcase.to_sym
    end

    def validate
      raise ArgumentError, "missing app_id" if app_id.to_s.empty?
      raise ArgumentError, "missing rack config file #{rack_file}" unless File.readable?(rack_file)
      raise ArgumentError, "invalid workers" unless workers.is_a?(Fixnum)
      raise ArgumentError, "invalid min_workers" unless min_workers.is_a?(Fixnum)
      raise ArgumentError, "invalid max_workers" unless max_workers.is_a?(Fixnum)
      raise ArgumentError, "invalid workers < min_workers" if workers < min_workers
      raise ArgumentError, "invalid workers > max_workers" if workers > max_workers
      raise ArgumentError, "invalid min_workers > max_workers" if min_workers > max_workers
      raise ArgumentError, "invalid logger" unless [:fatal, :error, :warn, :info, :debug].all?{|method| logger.respond_to?(method)}
      raise ArgumentError, "missing pidfile - required for daemon" if daemonize && pidfile.to_s.empty?
      raise ArgumentError, "missing logfile - required for daemon" if daemonize && logfile.to_s.empty?
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
