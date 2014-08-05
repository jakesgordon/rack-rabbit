require 'bunny'
require 'json'
require 'rack'

require 'rack-rabbit/request'
require 'rack-rabbit/response'

module RackRabbit
  class Worker

    #--------------------------------------------------------------------------

    attr_reader :server,
                :config,
                :logger,
                :app

    def initialize(server, app)
      @server = server
      @config = server.config
      @logger = server.logger
      @app    = app
    end

    #--------------------------------------------------------------------------

    def run
      logger.info "STARTED a new worker with PID #{Process.pid}"
      trap_signals
      conn, channel, exchange, queue = connect_to_rabbit
      queue.subscribe(:block => true) do |delivery_info, properties, payload|
        request  = Request.new(delivery_info, properties, payload)
        response = handle(request)
        if request.should_reply?
          exchange.publish(response.body, response_properties(request, response))
        end
      end
    ensure
      channel.close unless channel.nil?
      conn.close unless conn.nil?
    end

    #--------------------------------------------------------------------------

    def connect_to_rabbit
      conn = Bunny.new
      conn.start
      channel = conn.create_channel
      exchange = channel.default_exchange
      queue    = channel.queue(config.queue)
      channel.prefetch(1)
      [ conn, channel, exchange, queue ]
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

    def trap_signals

      [:QUIT, :TERM, :INT].each do |sig|
        trap(sig) do
          exit
        end
      end

      [:CHLD, :TTIN, :TTOU].each do |sig|
        trap(sig, :DEFAULT)
      end

    end

    #==========================================================================

  end
end
