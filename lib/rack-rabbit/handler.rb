require 'rack-rabbit/response'

module RackRabbit
  class Handler

    #--------------------------------------------------------------------------

    attr_reader :app, :config, :logger

    #--------------------------------------------------------------------------

    def initialize(app, config)
      @app    = app
      @config = config
      @logger = config.logger
    end

    #--------------------------------------------------------------------------

    def handle(message)

      env = message.get_rack_env(config.rack_env)

      status, headers, body_chunks = app.call(env)

      body = []
      body_chunks.each{|c| body << c }
      body_chunks.close if body_chunks.respond_to?(:close)

      Response.new(status, headers, body.join)

    rescue Exception => e    # don't let exceptions bubble out of worker process

      logger.error e
      logger.error e.backtrace.join("\n")

      Response.new(500, {}, "Internal Server Error")

    end

    #--------------------------------------------------------------------------

  end # class Handler
end # module RackRabbit
