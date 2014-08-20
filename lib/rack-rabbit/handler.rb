require 'rack'
require 'stringio'

require 'rack-rabbit/response'
require 'rack-rabbit/adapter'

module RackRabbit
  class Handler

    #--------------------------------------------------------------------------

    attr_reader :app,     # the rack app provided by the Server
                :config,  # configuration options provided by the Server
                :logger,  # convenience for config.logger
                :rabbit,  # rabbitMQ adapter constructed by this class
                :lock     # mutex to synchronize with Worker#shutdown for graceful QUIT handling

    #--------------------------------------------------------------------------

    def initialize(app, config, lock = nil)
      @config = config
      @logger = config.logger
      @rabbit = Adapter.load(config.rabbit)
      @app    = app
      @lock   = lock
    end

    #--------------------------------------------------------------------------

    def subscribe
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
    end

    def unsubscribe
      rabbit.disconnect
      rabbit.shutdown
    end

    #--------------------------------------------------------------------------

    def log(message, response, timing)
      logger.info "\"#{message.method} #{message.path}\" [#{response.status}] - #{"%.4f" % timing}"
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

      response = Response.new(500, {}, "Internal Server Error")

    ensure

      if message.should_reply?
        rabbit.publish(response.body, response_properties(message, response))
      end

      if !message.confirmed? && config.acknowledge
        rabbit.confirm(message, response.succeeded?)
      end

      response

    end

    #--------------------------------------------------------------------------

    def build_env(message)

      default_env.merge({
        'rabbit.message' => message,
        'rack.input'     => StringIO.new(message.body || ""),
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

  end # class Handler
end # module RackRabbit
