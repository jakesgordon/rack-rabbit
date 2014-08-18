require 'json'
require 'rack'

require 'rack-rabbit/signals'
require 'rack-rabbit/adapter'
require 'rack-rabbit/response'

module RackRabbit
  class Worker

    #--------------------------------------------------------------------------

    attr_reader :server,
                :config,
                :logger,
                :signals,
                :lock,
                :rabbit,
                :app

    def initialize(server, app)
      @server  = server
      @config  = server.config
      @logger  = server.logger
      @signals = Signals.new
      @lock    = Mutex.new
      @rabbit  = Adapter.load(config.rabbit)
      @app     = app
    end

    #--------------------------------------------------------------------------

    def run

      logger.info "STARTED a new worker with PID #{Process.pid}"

      trap_signals

      rabbit.startup
      rabbit.connect
      rabbit.subscribe(config.queue, :ack => config.acknowledge) do |message|
        lock.synchronize do
          start = Time.now
          response = handle(message)
          finish = Time.now
          log(message, response, finish - start)
        end
      end

      while true
        sig = signals.pop   # BLOCKS until there is a signal
        case sig
        when :INT  then shutdown(:INT)
        when :QUIT then shutdown(:QUIT)
        when :TERM then shutdown(:TERM)
        else
          raise RuntimeError, "unknown signal #{sig}"
        end
      end

    ensure
      rabbit.disconnect
      rabbit.shutdown

    end

    #--------------------------------------------------------------------------

    def log(message, response, timing)
      logger.info "\"#{message.method} #{message.path}\" [#{response.status}] - #{"%.4f" % timing}"
    end

    #--------------------------------------------------------------------------

    def shutdown(sig)
      lock.lock if sig == :QUIT # graceful shutdown should wait for any pending message handler to finish
      logger.info "#{RackRabbit.friendly_signal(sig)} worker #{Process.pid}"
      exit
    end

    #--------------------------------------------------------------------------

    def response_properties(message, response)
      return {
        :app_id           => config.app_id,
        :routing_key      => message.reply_to,
        :correlation_id   => message.correlation_id,
        :timestamp        => Time.now.to_i,
        :headers          => response.headers.merge(RackRabbit::HEADER::STATUS => response.status),
        :content_type     => response.content_type,
        :content_encoding => response.content_encoding
      }
    end

    #--------------------------------------------------------------------------

    def handle(message)

      env = build_env(message)

      status, headers, body_chunks = app.call(env)

      body = body_chunks.join
      body_chunks.close if body.respond_to?(:close)

      response = Response.new(status, headers, body)

    rescue Exception => e    # don't let exceptions bubble out of worker process

      logger.error e
      logger.error e.backtrace.join("\n")

      response = Response.new(500, {}, "")

    ensure

      if message.should_reply?
        rabbit.publish(response.body, response_properties(message, response))
      end

      if !message.confirmed? && config.acknowledge
        if response.succeeded?
          message.ack
        else
          message.reject   # we can configure rejected messages to show up in a dead-letter queue for debugging
        end
      end

      response

    end

    #--------------------------------------------------------------------------

    def build_env(message)

      default_env.merge({
        'rabbit.message' => message,
        'rack.input'     => StringIO.new(message.body),
        'REQUEST_METHOD' => message.method,
        'REQUEST_PATH'   => message.uri,
        'PATH_INFO'      => message.path,
        'QUERY_STRING'   => message.query,
        'CONTENT_TYPE'   => message.content_type,
        'CONTENT_LENGTH' => message.content_length
      }).merge(message.headers)

    end

    #--------------------------------------------------------------------------

    def default_env
      @default_env ||= {
        'rack.version'      => Rack::VERSION,
        'rack.logger'       => logger,
        'rack.errors'       => $stderr,
        'rack.multithread'  => false,
        'rack.multiprocess' => true,
        'rack.run_once'     => false,
        'rack.url_scheme'   => 'http',
        'SERVER_NAME'       => config.app_id
      }
    end

    #--------------------------------------------------------------------------

    def trap_signals  # overwrite the handlers inherited from the server process

      [:QUIT, :TERM, :INT].each do |sig|
        trap(sig) do
          signals.push(sig)
        end
      end

      trap(:CHLD, :DEFAULT)
      trap(:TTIN, nil)
      trap(:TTOU, nil)

    end

    #--------------------------------------------------------------------------

  end
end
