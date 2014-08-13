require 'json'
require 'rack'

require 'rack-rabbit/signals'
require 'rack-rabbit/helpers'
require 'rack-rabbit/request'
require 'rack-rabbit/response'

module RackRabbit
  class Worker

    #--------------------------------------------------------------------------

    include Helpers

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
      @rabbit  = load_adapter(config.adapter)
      @app     = app
    end

    #--------------------------------------------------------------------------

    def run

      logger.info "STARTED a new worker with PID #{Process.pid}"

      trap_signals

      rabbit.connect
      rabbit.subscribe(config.queue) do |request|
        lock.synchronize {
          response = handle(request)
          if request.should_reply?
            rabbit.publish(response.body, response_properties(request, response))
          end
        }
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

    end

    #--------------------------------------------------------------------------

    def shutdown(sig)
      lock.lock if sig == :QUIT # graceful shutdown should wait for any pending request handler to finish
      logger.info "#{friendly_signal(sig)} worker #{Process.pid}"
      exit
    end

    #--------------------------------------------------------------------------

    def response_properties(request, response)
      return {
        :app_id           => config.app_id,
        :routing_key      => request.reply_to,
        :correlation_id   => request.message_id,
        :timestamp        => Time.now.to_i,
        :headers          => response.headers,
        :content_type     => response.content_type,
        :content_encoding => response.content_encoding
      }
    end

    #--------------------------------------------------------------------------

    def handle(request)

      env = build_env(request)

      status, headers, body_chunks = app.call(env)

      body = body_chunks.join
      body_chunks.close if body.respond_to?(:close)

      Response.new(status, headers, body)

    end

    #--------------------------------------------------------------------------

    def build_env(request)

      default_env.merge({
        'rack.input'     => StringIO.new(request.body),
        'REQUEST_METHOD' => request.method,
        'REQUEST_PATH'   => request.uri,
        'PATH_INFO'      => request.path,
        'QUERY_STRING'   => request.query,
        'CONTENT_TYPE'   => request.content_type,
        'CONTENT_LENGTH' => request.content_length
      }).merge(request.headers)

    end

    #--------------------------------------------------------------------------

    def default_env
      @default_env ||= {
        'rack.version'      => Rack::VERSION,
        'rack.logger'       => logger,
        'rack.errors'       => logger,
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
